# NOTES

Pulse - a live market watchlist over a deliberately hostile SSE feed.

---

## 1. The central decision: two planes

Everything else follows from this split.

**Control plane** - `FeedConnectionBloc`. Is there a healthy stream? Should we
reconnect, and when? Is the token about to die? Is the device online? These
change a handful of times a minute, so emitting a bloc state per change is free.

**Data plane** - `PriceBloc`. Ticks arrive at ~50-60/sec at baseline and 220 in
a single burst. They are dedup'd, ordered and conflated, and reach `emit` only
once per ~16ms window - never one at a time.

The brief says a full-list rebuild on every tick will not pass. Emitting per
tick *is* that full-list rebuild, so the split is not a stylistic preference -
it is the requirement. A row's symbol and name build once; only the price pair
sits inside a `BlocSelector`; `RepaintBoundary` stops a flashing row repainting
its neighbours.

Two details carry that contract, and both are easy to break silently, so both
are tested:

- **`PriceState` equality is a revision counter, hand-written rather than
  freezed.** Freezed generates `DeepCollectionEquality` for collection fields,
  so bloc would deep-compare every quote on every emit purely to decide whether
  to emit - O(symbols) of waste at frame cadence.
- **The quote map is copy-on-write, and unchanged cells keep their identity.**
  `BlocSelector` only skips a rebuild when the selected value is unchanged. If
  a flush ever rebuilt every cell, every visible row would rebuild on every
  flush and nothing would look wrong until DevTools was open.

`test/presentation/widgets/price_row_rebuild_test.dart` pins this: 220 ticks
rebuild *nothing* above the price leaf.

### Why this is a bloc and not a store

An earlier version of this used a `PriceStore` exposing a per-symbol
`ValueNotifier` that widgets subscribed to directly. It performed identically -
and I want to be precise about that, because it is the interesting part:

At forty instruments the two designs are **indistinguishable**. `BlocSelector`
does not call `setState` when the selected value is unchanged, so widget rebuild
counts are the same. `ListView.builder` unmounts off-screen rows, so the
selector fan-out is bounded by what is visible (~12), not by the instrument
count. The residual cost of the bloc version - one new map per flush, one
equality check per emit - is microseconds per second.

`ValueNotifier` does scale better: notification is per-symbol by construction,
so untouched symbols cost literally zero rather than a cheap comparison. That
advantage would start to matter at several hundred symbols. It does not matter
here.

What decided it was ownership, not performance. With the store, the most
frequently changing UI-facing state in the app was the one piece that did not
live in a bloc, and widgets reached past the bloc layer to subscribe to a data
object. That is a real deviation from the architecture the brief asks for, and
"it is faster" was not a good enough reason for it when it measurably is not.

The blocs now own the whole picture: connection lifecycle in one, market data
in the other, with the correctness logic factored into `QuoteBook` - a pure,
framework-free collaborator that decides what is *true* while the bloc decides
how it is presented.

## 2. Conflation: 16ms, and what it costs

Accepted ticks land in a `Map<String, Tick>` (last write wins per symbol) and
publish on a 16ms timer. A 220-tick burst across 5 hot symbols becomes **5
notifier writes on the next flush** - the same cost as five ordinary ticks.

**Why 16ms** rather than something slower: it is one frame at 60Hz. Anything
slower is throwing away freshness for headroom we do not need once conflation
has already collapsed the burst by ~40x. Anything faster does no work a frame
can show. It is a single constant in `AppConfig`.

**Why a timer rather than `addPostFrameCallback`**: post-frame callbacks only
run if a frame was already scheduled. When the tree is otherwise idle nothing
schedules one, so the first tick after a quiet moment would sit in the buffer
indefinitely. `ConflationScheduler` is an interface, so tests flush on demand
instead of waiting on real time.

**What is lost**: intermediate prices within a 16ms window. For a watchlist
this is not information - nobody can read a number that was on screen for 8ms.
It *would* be information for a tape or a candle chart, and it is a real
limitation of the sparkline on the detail screen: history is appended at drain
time, so it samples post-conflation, not every tick. If the sparkline needed
tick-accurate shape, history would have to be fed from `add()` instead - at the
cost of a single burst flooding the ring buffer with 220 samples. There is a
test asserting the current behaviour, so it stays a decision rather than drifting.

## 3. Ordering, and something the brief does not mention

Three ordered filters:

These live in `QuoteBook`, deliberately free of any notion of how updates reach
the screen:

1. **Duplicate suppression by SSE id** - a fixed-size ring of the last 2048 ids.
   Catches the server's byte-identical replays. O(1), flat memory. The window is
   sized against the server's own 1000-event replay buffer, so it comfortably
   covers anything the server can legitimately re-send.
2. **Ordering guard on `(ts, id)`** - drops anything not strictly newer.
3. **Conflation** - as above.

Filter 1 cannot catch the server's out-of-order event: `outOfOrder()` emits with
`ts - 3000` but a **brand new, higher id**. Only a per-symbol timestamp guard
sees it. Both layers are load-bearing, for different misbehaviours.

**The thing I got wrong first.** I originally treated an equal timestamp as a
replay and dropped it. Running against the real server showed
`out-of-order: 397` in 90 seconds - far more than the documented chaos schedule
can produce. The cause is `burst()`: it emits 220 ticks *synchronously*, so
dozens of ticks for one symbol carry an identical millisecond `ts`. Dropping
every tie pinned each hot row to the burst's *opening* price instead of its
closing one - a silent correctness bug that no amount of staring at the spec
would have surfaced.

Timestamps are not a total order here. The SSE `id` is globally monotonic, so
it breaks ties in true emission order: accept if `ts` is newer, or if `ts` is
equal and the id moved forward. After the fix the same 90 seconds reports
`out-of-order: 4`, which matches the chaos schedule. The counter became
meaningful, which is the point of having it.

## 4. What "no data loss" can and cannot mean

The server buffers **1000 events**. At the ~50-60 ticks/sec I measured, that is
roughly **15-20 seconds of history** - and a single burst consumes 220 of those
1000 slots instantly, so during a burst the window is much shorter still.

So:

- An outage shorter than the buffer window: `Last-Event-ID` replays everything
  we missed. Genuinely no loss.
- An outage longer than that: the server sends one `event: gap` and continues
  live. Those ticks are **gone permanently**. No client-side cleverness can
  recover them; the data no longer exists anywhere.

The honest response is to surface it, not paper over it. The banner shows a gap
counter with a tooltip explaining what it means. A price feed that quietly
implies continuity it does not have is worse than one that admits the hole.

Worth being precise about a second limit: "no loss" here means *no loss the
server can still serve*. Because we conflate, we also never render every tick -
we render every *price*, which for a watchlist is the same thing and for a chart
is not.

**On detecting holes ourselves.** Ids are monotonic, so a client *could* watch
for discontinuities rather than waiting to be told. Pulse does not, and for
this server that is a deliberate call rather than an oversight.

The server only drops events in one place: `write()` skips while a connection
is flagged stalled. Everything else is a contiguous, ordered TCP stream. And
because our own watchdog tears a silent socket down at 12s - well inside the
server's 25s stall - we always reconnect with `Last-Event-ID`, which either
replays the missed range or answers `gap`. Either way the server tells us. So
the two mechanisms are coupled: **server-side gap reporting is sufficient only
because the stall threshold is below the stall duration.** Raise
`stallReconnectAfter` past 25s and holes would start passing silently.

Naive `lastId + 1` detection would also be wrong here without care: duplicates
replay older ids, and the `gap` event and malformed lines carry no `id` of
their own (they inherit the last one, per spec), so a jump straight after a gap
is expected rather than a discovery. A correct implementation has to ignore
ids at or below the cursor and suppress the first jump after a gap notice.

Worth having against a real feed, where multiple upstreams and fan-out make
silent holes ordinary. Not worth the moving parts against this one.

## 5. Stall detection: 8s and 12s

The server's silent stall keeps the socket open and sends nothing - no ticks,
**no heartbeats** - for exactly 25 seconds. Heartbeats arrive every 5s when
healthy, which is what makes the stall detectable at all: silence past ~8s
cannot be a quiet market, only a broken connection.

- **8s of silence** -> `degraded`. The banner turns amber, names the silence in
  seconds, says the prices are not current, and the list dims.
- **12s of silence** -> tear the socket down and reconnect.

We deliberately do not wait the stall out. Riding it would mean up to 25 seconds
of frozen prices presented behind a connection that looks fine. Tearing down at
12s costs one reconnect and gets live data back in well under a second.

The watchdog is a **single 1s periodic timer** comparing an injected clock
against the last-activity timestamp - not a timer reset on every tick. At 60-90
ticks/sec, resetting a timer per tick is pure allocation churn for no benefit.

## 5b. App lifecycle

Backgrounding was survivable before any of this existed, by accident of an
earlier decision: the watchdog compares **wall-clock** time rather than
resetting a timer per tick, so a suspended app is indistinguishable from a
stalled feed and the existing recovery path just handles it. Two things were
still wrong.

**The resume window lied.** On foregrounding, the phase was still `live` until
the watchdog's next 1s tick - a green banner above prices that could be minutes
old. That is a direct hit on the one UI requirement the brief states in
absolute terms. The fix is not on resume but on the way out: entering a
`suspended` phase when the app is backgrounded means there is no frame on which
the banner can claim live over pre-suspension data.

**We kept streaming whenever the OS allowed it**, spending battery, data and
the server's finite replay buffer on data nobody could see.

So: `pause` tears the connection down and suppresses attempts exactly the way
being offline does. `resume` resets backoff and reconnects immediately -
returning is new information, not another failure.

Only `pause` is wired, never `inactive`. The sequence out is
resumed -> inactive -> hidden -> paused, and `inactive` alone fires for the app
switcher, Control Centre, an incoming call, a permission dialog. Dropping the
feed there would mean a reconnect every time someone glanced at their
notifications. There is a test pinning that distinction because it is exactly
the kind of thing that regresses quietly.

Disconnect is immediate rather than after a grace period. Given the server drops
every connection within 25-55s anyway, a reconnect is cheap; a short grace
window would be kinder to someone flicking between apps, and is the obvious
refinement if this were real.

### A transport bug this uncovered

Verifying with `lsof` rather than trusting the code showed the socket was
**still ESTABLISHED** after teardown. Cancelling the response subscription
stops us consuming, but `HttpClient` hands the socket back to its persistent
connection pool - so the server carried on writing ticks into a connection
nobody was reading, holding its own timers and buffer open.

This affected *every* teardown, not just backgrounding: each stall-triggered
reconnect left one behind. Connections are now marked non-persistent and the
request is aborted on close. Measured afterwards: 1 socket -> 0 on background,
holding 0, back to 1 within 3s of resume.

The lesson worth stating: "we called close()" and "the socket is closed" are
different claims, and only one of them can be checked.

## 6. Backoff and token expiry

500ms base, doubling, capped at **15s**, with +/-20% jitter from an injected
`Random`. The cap matters as much as the growth: "don't wait forever" argues
against the 30-60s caps you often see.

Two rules that stop the sequence being naively mechanical:

**Healthy streams earn a clean slate.** A stream that ran 10s before dropping
resets the attempt counter, so one long-lived connection dying does not inherit
an old backoff step. This is also what makes stall recovery fast without any
special-casing for stalls.

**Expected drops cost nothing.** The server closes *every* connection the moment
its token expires - a 1s timer per connection enforces it - so at a 60s TTL,
every stream dies within a minute no matter what. A drop within 2s of the token
expiry we already know about reconnects with **zero backoff**. Without this the
app would visibly stutter once a minute, forever, for an entirely predictable
event.

Token handling:
- Proactive refresh at 45s (15s before expiry), so the fresh token is already in
  hand when the inevitable drop lands and the reconnect needs no login round-trip.
- Reactive: a 401 refreshes once and retries immediately. A 401 on a *freshly
  issued* token means the credentials themselves are bad - the only path that
  ever puts a human back in front of a login form.
- Refreshes are coalesced: the proactive timer and a 401 handler can fire
  together, and two logins would race over which token wins.

`AuthRepository` is deliberately timer-free. All scheduling lives in the feed
bloc, so there is exactly one place where time-based behaviour has to be
reasoned about - and one place to point `fakeAsync` at.

## 7. The native piece (iOS)

`packages/pulse_native` - hand-written channel code, no `flutter_secure_storage`,
no `connectivity_plus`.

- **MethodChannel** `pulse_native/secure_storage` -> Keychain
  (`kSecClassGenericPassword`). Namespaced by bundle id so `deleteAll` cannot
  reach other apps' secrets. Accessibility `kSecAttrAccessibleAfterFirstUnlock`
  so the feed survives a locked screen. Writes are update-then-add, so a key is
  never momentarily absent. `OSStatus` failures map to a stable Dart exception
  code; a missing plugin registration is reported distinctly, because that is a
  wiring bug rather than a storage failure.
- **EventChannel** `pulse_native/reachability` -> `NWPathMonitor`. It fires its
  handler immediately on start, so the first event a subscriber gets is the
  current state, not the next change - no "unknown" gap at launch.

Used in the reconnect logic: going offline tears the connection down and cancels
pending backoff; while offline **zero** attempts are made; coming back online
resets backoff and reconnects at once, because reachability returning is new
information rather than another failure.

**Second platform.** The Dart side uses the standard federated shape -
`PulseNativePlatform` as an abstract class with a swappable static instance -
so Android is one more subclass over `EncryptedSharedPreferences` +
`ConnectivityManager`, selected in `_defaultInstance()`. Nothing above that line
changes. Every non-iOS platform currently gets `InMemoryPulseNative`, a stub
that keeps the app runnable and says out loud that it is not secure storage.

**Security tradeoff, stated plainly.** The brief requires no user intervention
after the initial login. Tokens live 60 seconds and there is no refresh-token
endpoint, so a persisted *token* is essentially always dead by the next cold
start. Meeting the requirement therefore means persisting the **credentials**,
not just the token, and that is what Pulse does - username, password and token
all in the Keychain. I would not ship this against a real broker. A real system
would issue a long-lived refresh token, store only that, and gate its use behind
biometric authentication. Given this server's API, storing credentials is the
only way to satisfy the requirement; the right response is to be explicit about
it rather than hide it.

## 8. Tests: what I chose and why

104 tests in the app plus 11 in the plugin. Chosen for risk, not coverage.

- **`sse_parser_test`** (20) - the field grammar, comments as first-class
  messages, id persistence across id-less events, one-byte-at-a-time chunk
  boundaries, CRLF, a multi-byte character split across packets, and every
  malformed shape the server produces.
- **`feed_connection_bloc_test`** (20) - the whole state machine against a fake
  transport and `fake_async`: the exact backoff sequence with a seeded RNG,
  early-retry rejection, healthy-reset, degrade-then-teardown, heartbeats
  holding a connection live, proactive refresh timing, 401-then-retry,
  reachability gating (asserting *zero* transport calls while offline), and
  resume ids. No real server, no real time.
- **`quote_book_test`** (14) - the filters in isolation: tie-breaking by id, a
  whole burst inside one millisecond, conflation collapse, dedup-window
  eviction, session extremes surviving the ring buffer.
- **`price_bloc_test`** (12) - that 220 ticks produce exactly *one* emission,
  that untouched symbols keep the identical cell instance, that a counters-only
  flush leaves every quote instance alone, and the flash semantics.
- **`auth_repository_test`** (11) - the silent-restore path, corrupt stored
  expiry, refresh coalescing.
- **`reconnect_policy_test`** (4) - exact sequence, jitter bounds, jitter
  actually varying, and no overflow on a very long outage.
- **`price_row_rebuild_test`** (4) - the performance contract end to end: 220
  ticks rebuild nothing above the price leaf. This is the guard rail for the
  whole design.
- **`app_lifecycle_bridge_test`** (3) - background drops the feed, resume
  restores it, and a transient `inactive` does neither.
- **`connection_banner_test`** (8) - each phase says something the user can act
  on. Catching the 4-second stalled window by screenshot is luck; asserting it
  is not.
- **`watchlist_recovery_test`** (3) - the feed recovering also recovers the
  screen. See below.

Two real bugs were found by tests rather than by me:
- The flash controller ran `forward(from: 1)`, so the wash started fully faded
  and **no flash was ever visible**.
- An ordering bug in the bloc: teardown cleared the stream's open-time and token
  expiry *before* the code that read them, so healthy-reset and expected-drop
  detection both silently never fired.

Two more were found only by running the thing, which is the honest argument for
doing both:
- The equal-timestamp bug in §3.
- **The feed recovered but the screen did not.** The server died while the app
  was open. The feed did everything right - backed off, capped at 15s, re-logged
  in silently when the server returned, went green. But `/instruments` is
  fetched once, so the watchlist stayed pinned to its error screen while ticks
  poured into a store with no rows to render them. The connection said "Live"
  above an empty list. Fixed by retrying the instrument load when the feed
  transitions to live, which is the app's own proof the server is answering
  again. This is the kind of bug that unit tests structurally cannot find: every
  component was behaving correctly on its own.

## 9. What I cut, and what I would do next

**Cut deliberately:**
- **Android implementation of the plugin.** The brief asks for one platform;
  building two would have been effort spent proving something already agreed.
  The Dart API is shaped for it and the stub keeps the app runnable.
- **Search / sort / filter on the watchlist.** Not asked for, and it would have
  complicated the list-identity story that the rebuild test depends on.
- **Persisting prices across launches.** A watchlist that opens showing
  yesterday's numbers is worse than one that opens empty for 200ms.
- **A logging/telemetry layer.** The diagnostics row covers the same need for a
  take-home and is visible during grading.

**Next, in order:**
1. **Client-side gap detection.** Ids are monotonic, so a jump of more than 1
   means events were lost even when the server does not announce it. Today we
   only count the gaps the server tells us about (§4).
2. **Profile-mode frame measurement on a physical device.** See §10.
3. **Android plugin implementation.**
4. **A reconnect storm test** - many rapid connect/drop cycles asserting no
   leaked subscriptions or overlapping sockets. The generation counter exists
   precisely for this and deserves a test rather than an argument.
5. **Tick-accurate history** for the sparkline, if the detail screen ever grew
   into a real chart (§2).

## 10. Known gaps and things I am aware of

- **Frame timing is asserted structurally, not measured on real hardware.** The
  rebuild test proves ticks do not propagate above the price leaf, which is the
  mechanism the requirement is about. I could not complete a profile-mode
  measurement: the simulator does not support profile mode, and the physical
  device could not reach the feed server because this Mac's firewall blocks all
  incoming connections under an MDM profile that cannot be changed. In debug
  mode on the simulator - a strict upper bound, since debug builds are heavily
  instrumented - build times were p50 1.7ms / p95 5.5ms and raster p50 0.9ms /
  p95 2.2ms across ~5500 frames including bursts. **Please run it in profile
  mode on a device**; the numbers above are indicative, not proof, and I would
  rather label them than present them as more than they are.
- **Lifecycle was verified on the simulator, which does not truly suspend
  apps.** The socket measurements above are real, and iOS delivered the full
  `inactive -> hidden -> paused` sequence, but a physical device also freezes
  timers and may kill the socket from underneath us. The wall-clock watchdog
  covers that case by construction; I have not been able to observe it.
- **The `--calm` flag is untested by me.** I built and verified against the
  chaotic default throughout.
- **The stale badge is per-symbol and time-based**, so a genuinely illiquid
  instrument (the `rate == 2` group ticks about once every 5s) can badge itself
  stale during a normal quiet stretch. The threshold is 8s and tunable; a real
  product would scale it per instrument's expected tick rate.
- **`InMemoryPulseNative` reports "always online"**, so on a non-iOS platform
  the reconnect logic loses its offline suppression. Documented in the package
  README, and the login screen warns when secure storage is not native.
- **No coverage of the widget tree above the row** beyond the banner - the
  watchlist screen itself has no golden or integration test.
- The connection banner rebuilds once a second while visible to run its
  countdown. That is one small widget, deliberately, rather than a bloc emitting
  a state per second.

## 11. How I used AI tools

I drove Claude Code (Opus) for essentially all of the typing, working from a
plan we agreed up front: I answered ~30 scoping questions about architecture,
thresholds, and tradeoffs before any code existed, and that plan is committed as
`PLAN.md` so the decisions are auditable against what actually got built.

Where it did the work: scaffolding, the Swift channel code, test bodies, and the
mechanical parts of the widget tree. Where I made the calls: the control/data
plane split, the conflation rate, the 8s/12s stall thresholds, ordering by
`(ts, id)`, storing credentials rather than only the token, and what to cut.

Two things are worth noting about the process, because they cut against the
"AI wrote it" reading. First, the equal-timestamp bug (§3) was found by reading
the *server's* source and then watching a counter misbehave against the live
feed - not by generating more code. Second, several of the sharper decisions
came from treating `feed_server.dart` as the specification rather than the
prose: the 5s heartbeat, the 25s stall, the 1000-event buffer, the synchronous
burst, and the per-connection token timer are all facts about the server that
change the design, and none of them are in the brief.
