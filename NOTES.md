# Notes

## Architecture

The app is split into a **control plane** and a **data plane**, and everything
else follows from that.

`FeedConnectionBloc` owns the connection lifecycle: connect, detect stalls, back
off, refresh tokens, react to reachability. Those things change a few times a
minute, so emitting a state for each one is free.

`PriceBloc` owns market data. Ticks arrive at ~50-60/sec and 220 at once during a
burst. They are deduplicated, ordered and conflated, and only reach `emit` once
per ~16ms window. `QuoteBook` sits underneath it as a plain Dart class holding
the correctness rules, so they can be tested without any bloc machinery.

The brief says a full-list rebuild on every tick will not pass. Emitting per tick
*is* that rebuild, so this split is the requirement rather than a preference. In
the widget tree, the symbol and name build once, and only the price pair sits
inside a `BlocSelector`.

Two details make that work, and both are easy to break by accident, so both have
tests:

- `PriceState` equality is a revision counter, written by hand. Freezed would
  generate deep collection equality, so bloc would compare every quote on every
  emit just to decide whether to emit.
- The quote map is copy-on-write and unchanged cells keep their identity, so
  `BlocSelector` skips those rows on reference equality.

I originally built the data plane as a `PriceStore` exposing `ValueNotifier`s
that widgets listened to directly. It performed identically - `BlocSelector`
doesn't call `setState` when the selection is unchanged, and `ListView.builder`
only mounts visible rows, so the fan-out is about a dozen either way. I moved it
to a bloc because the store meant the most frequently changing state in the app
was the one piece not owned by a bloc, and widgets reached past the bloc layer to
get it. Ownership decided it, not speed.

## Conflating bursts, and at what rate

Accepted ticks go into a `Map<String, Tick>` keyed by symbol, last write wins,
flushed on a 16ms timer. A 220-tick burst across 5 hot symbols becomes 5 cell
updates on the next flush.

**Why 16ms:** one frame at 60Hz. Slower throws away freshness for headroom I
don't need once conflation has already collapsed the burst ~40x. Faster does work
no frame can show. It's a single constant in `AppConfig`.

I used a timer rather than `addPostFrameCallback` because post-frame callbacks
only run if a frame was already scheduled, and when the tree is idle nothing
schedules one - the first tick after a quiet moment would sit in the buffer.

**What this costs:** prices that existed for less than 16ms are never drawn.
Nobody can read those, so for a watchlist it isn't information. It would be for a
chart, and it's a real limitation of the detail screen's sparkline, which samples
after conflation rather than every tick.

## What "no data loss" can and cannot mean

The server buffers 1000 events. At the ~50-60 ticks/sec I measured that's roughly
15-20 seconds of history, and a single burst eats 220 of those slots at once.

- Outage shorter than that: `Last-Event-ID` replays everything missed. No loss.
- Outage longer: the server sends one `gap` and continues live. Those ticks are
  gone permanently, and no client-side cleverness can recover them.

So I surface it instead of hiding it: the banner shows a gap counter. A feed that
quietly implies continuity it doesn't have is worse than one that admits the hole.

I don't detect id discontinuities myself, and that's deliberate. The server only
drops events while a connection is flagged stalled, and because my watchdog tears
a silent socket down at 12s - inside the server's 25s stall - I always reconnect
with `Last-Event-ID` and get either a replay or a `gap`. The two are coupled:
server-side gap reporting is sufficient *because* the stall threshold sits below
the stall duration. Raise it past 25s and holes would start passing silently.

## Resilience decisions

Numbers came from reading `feed_server.dart` rather than the brief: heartbeats
every 5s, stalls lasting exactly 25s, disconnects at 25-55s, a 60s token, a
1000-event buffer, and a burst that emits synchronously.

**Stalls.** 8s of silence marks the feed degraded; 12s tears the socket down. I
don't wait out the server's 25s stall, because that would mean up to 25 seconds of
frozen prices behind a connection that looks fine. The watchdog is one 1s timer
comparing an injected clock, not a timer reset per tick - at 60-90 ticks/sec that
would be pure allocation churn. It also means a suspended app is indistinguishable
from a stalled feed, so backgrounding recovers through the same path.

**Backoff.** 500ms doubling to a 15s cap, ±20% jitter. A stream that ran healthily
for 10s resets the counter, which is also what makes stall recovery fast without
special-casing it.

**Tokens.** The server closes every connection the moment its token expires, so
every stream dies within a minute regardless. I refresh at 45s, and a drop within
2s of a known expiry reconnects with zero backoff - otherwise the app would
visibly stutter once a minute for an entirely predictable event. A 401 refreshes
once and retries; a 401 on a fresh token is a real auth failure and the only path
back to the login screen.

**Background.** On `pause` I drop the connection and stop attempting; on `resume`
I reset backoff and reconnect immediately. Only `pause`, never `inactive` - that
fires for the app switcher and Control Centre, and dropping the feed there would
reconnect every time someone checks their notifications.

## The native piece (iOS)

`packages/pulse_native`, hand-written channels. Keychain over a MethodChannel,
`NWPathMonitor` over an EventChannel. No `flutter_secure_storage`, no
`connectivity_plus`.

Reachability is wired into reconnect logic: going offline tears the connection
down and cancels pending backoff, and while offline I make zero attempts. Coming
back resets backoff and reconnects at once, because reachability returning is new
information rather than another failure.

The Dart side uses the standard federated shape, so Android is one more subclass
over EncryptedSharedPreferences + ConnectivityManager selected in one place.
Non-iOS platforms get an in-memory stub that keeps the app runnable and says out
loud that it isn't secure storage.

**Security tradeoff.** The brief wants no user intervention after the first login.
Tokens live 60 seconds and there's no refresh-token endpoint, so a stored token is
almost always dead by the next cold start. Meeting the requirement therefore means
storing the *credentials*, which is what I do. I wouldn't ship this against a real
broker - that wants a long-lived refresh token, stored alone, behind biometrics.
Given this API it's the only way to satisfy the requirement, so I'd rather be
explicit about it than hide it.

## The tests I chose

I picked by risk, not coverage. The four that matter:

1. **The connection state machine**, against a fake transport and `fake_async`:
   the exact backoff sequence with a seeded RNG, that it doesn't retry early,
   degrade-then-teardown on a stall, heartbeats holding a connection live, token
   refresh timing, 401-then-retry, and that being offline produces *zero*
   transport calls. No real server and no real time - this is the logic most
   likely to break and hardest to reproduce by hand.
2. **The tick pipeline**: duplicates by id, stale timestamps, tie-breaking by id,
   and a whole burst inside one millisecond. These encode the feed's documented
   misbehaviours, so they'd catch a regression against the real server.
3. **Rebuild isolation**: 220 ticks must rebuild nothing above the price leaf.
   This is the graded performance property, and it's the kind of thing that
   regresses silently - lose reference stability on unchanged cells and every row
   rebuilds with nothing visibly wrong.
4. **The SSE parser**: the field grammar, comments as first-class messages,
   one-byte-at-a-time chunk boundaries, and every malformed shape the server
   produces. It's pure and cheap to test, and it's the layer everything else sits on.

Beyond those: the banner's wording in every phase (the "never look at frozen
prices believing they're live" requirement is a rendering contract, not just a
state machine one), the lifecycle transitions, and silent re-login on cold start.

Three bugs were caught by tests rather than by me: the flash animation ran
`forward(from: 1)` so no flash was ever visible; teardown cleared the stream's
open-time before the code that read it, silently disabling backoff reset; and the
connection bloc emitted on every tick because `lastEventId` lived in its state -
the comment above it claimed the opposite of what the code did.

Two more only showed up by running it, which is the argument for doing both. The
server's burst is synchronous, so dozens of ticks per symbol share one millisecond
timestamp; my first ordering rule dropped every tie and pinned each hot row to the
burst's *opening* price. And when the server died mid-session the feed recovered
perfectly but the instrument list stayed stuck on its error screen - a green
"Live" banner above an empty list, with every component behaving correctly on its
own.

## What I cut

- **Android for the native piece.** The brief asks for one platform. The Dart API
  is shaped for the second and the stub keeps the app runnable there.
- **Search, sort and filter** on the watchlist. Not asked for, and it complicates
  the list identity the rebuild test depends on.
- **Persisting prices across launches.** Opening on yesterday's numbers is worse
  than opening empty for 200ms.
- **A logging layer.** The diagnostics row covers the same need here and is
  visible while the app runs.

Next, in order: client-side gap detection (needed against a real feed, not this
one), the Android implementation, and a reconnect-storm test asserting no leaked
subscriptions across rapid connect/drop cycles.

## Known gaps

- **Frame timing is asserted structurally, not measured on hardware.** The rebuild
  test proves ticks don't propagate above the price leaf, but I couldn't complete
  a profile-mode measurement: the simulator doesn't support profile mode, and my
  device couldn't reach the server because this Mac's firewall blocks incoming
  connections under an MDM profile I can't change. In debug on the simulator -
  an upper bound, since debug builds are instrumented - build times were p50
  1.7ms / p95 5.5ms over ~5500 frames including bursts. Please check it in profile
  mode on a device; I'd rather label those numbers than oversell them.
- **Lifecycle was verified on the simulator, which doesn't truly suspend apps.**
  The socket measurements are real and iOS delivered the full
  `inactive -> hidden -> paused` sequence, but a device also freezes timers. The
  wall-clock watchdog covers that by construction; I haven't observed it.
- **The stale badge is time-based**, so a genuinely illiquid instrument can badge
  itself during a normal quiet stretch. Threshold is 8s and tunable; a real product
  would scale it per instrument.
- **I only built against the chaotic default.** I never exercised `--calm`.
- The connection banner rebuilds about once a second while visible to run its
  countdown. That's one small widget by choice, rather than the bloc emitting a
  state per second.

## How I used AI

I drove Claude Code throughout, working from a plan I agreed up front after
answering a round of scoping questions about architecture, thresholds and
tradeoffs.

It did most of the typing: scaffolding, the Swift channel code, test bodies, the
mechanical parts of the widget tree. I made the calls that shaped it - the
control/data plane split, the conflation rate, the 8s/12s stall thresholds,
ordering on `(ts, id)`, storing credentials rather than only the token, and what
to cut.

The parts I'm most confident in didn't come from generating more code. Reading
`feed_server.dart` as the real specification is where the thresholds came from,
and the ordering bug only surfaced because a counter looked wrong against the live
feed. I also verified claims rather than trusting them: teardown looked correct
but `lsof` showed the socket still ESTABLISHED, because cancelling a subscription
hands the connection back to `HttpClient`'s pool instead of closing it.
