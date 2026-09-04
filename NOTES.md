# Notes

## Main design choices

I split the app into two paths because connection state and price updates have
very different update rates.

`FeedConnectionBloc` handles the connection: opening the SSE stream, retries,
stall detection, token refresh, reachability and app lifecycle. `PriceBloc`
handles ticks. It delegates the ordering and deduplication rules to `QuoteBook`,
which is plain Dart and therefore easy to test without Flutter or a real socket.

That split matters for the burst requirement. Ticks are conflated before they
reach `PriceBloc` state, and rows select only their own `PriceCell`. The
watchlist itself is not rebuilt for a price update. The quote map is
copy-on-write, so cells for untouched symbols keep their identity and their
`BlocSelector`s do not rebuild.

I first used a `PriceStore` with `ValueNotifier`s. It was fast enough, but it
left the most active UI state outside the BLoC layer. Moving that state into
`PriceBloc` kept the same rendering behaviour and made ownership clearer.

## Bursts and ordering

Ticks are buffered by symbol for 16ms; the last tick for each symbol wins in
that window. A burst of 220 ticks across a few symbols becomes one UI update
with a few changed cells. Sixteen milliseconds is roughly one 60Hz frame. A
shorter interval cannot be shown, and a longer one would make the watchlist feel
needlessly behind.

The tradeoff is intentional: intermediate values inside that window are not
drawn. That is fine for a watchlist. It would not be fine for a trade tape or a
tick-accurate chart; the sparkline currently represents the conflated values.

`QuoteBook` applies two checks before buffering a tick:

- It remembers a bounded window of SSE ids and ignores duplicates.
- For each symbol, it rejects an older `(timestamp, event id)` pair.

The event id is needed as a tie-breaker. The server's burst is synchronous, so
many ticks can share the same millisecond timestamp. Comparing timestamps alone
made a row keep the first price in a burst instead of the latest one.

## Reconnect and recovery

I used the server implementation as the source for the thresholds: heartbeats
are sent every 5 seconds, a silent stall lasts 25 seconds, tokens last 60
seconds, and the replay buffer holds 1,000 events.

- At 8 seconds without either a tick or heartbeat, the UI changes to degraded.
- At 12 seconds, the client closes the connection and reconnects instead of
  waiting out a 25-second stall.
- Retry delay starts at 500ms, doubles up to 15 seconds, and includes 20%
  jitter. A connection that stayed healthy for 10 seconds resets the retry
  counter.
- When iOS reports no network, the client closes the stream and does not make
  retry attempts. It reconnects immediately when reachability returns.

The token is refreshed 15 seconds before expiry. The server will still close the
old stream at expiry, so a close near the known expiry reconnects immediately
with the refreshed token. A 401 triggers one refresh-and-retry; a second 401 is
treated as a genuine authentication failure.

When the app is paused, I close the feed rather than keeping a live socket for a
screen that is not visible. On resume, the app reconnects immediately and keeps
using `Last-Event-ID`. I deliberately do this on `pause`, not `inactive`, since
`inactive` also happens for transient UI interruptions.

## Resume semantics and gaps

The server can replay only what remains in its 1,000-event buffer. A short
disconnect resumes with `Last-Event-ID` and replays the missing messages. If the
id is too old, the server sends `event: gap`; the app keeps the latest prices and
shows a gap counter rather than implying the history was continuous.

I do not separately infer gaps from jumps in event ids. With this server, every
reconnect includes `Last-Event-ID`, and the 12-second watchdog reconnects well
before its 25-second stall ends. The server can therefore either replay the
events or explicitly send `gap`. For a real feed with different semantics, I
would add client-side sequence-gap detection as well.

## Native piece: iOS

The local `pulse_native` plugin contains the required native work:

- A `MethodChannel` stores, reads and removes secrets from the iOS Keychain.
- An `EventChannel` exposes `NWPathMonitor` reachability updates.

The Dart-facing API is behind `PulseNativePlatform`, so an Android
implementation can be added without changing the rest of the app. Android is
not implemented; non-iOS platforms use an in-memory fallback and the UI says so.

One security compromise is worth calling out. The API has no refresh token, and
a 60-second access token will normally be expired on the next launch. To meet
the requirement that the user only logs in once, I store the username and
password in Keychain as well as the current token. I would not use that design
for a real trading product: it should store a refresh token, ideally protected
by device authentication.

## Tests

The tests focus on the parts that are easy to break and hard to validate by
clicking through the app:

- The connection BLoC is exercised with a fake transport and fake time. This
  covers backoff, silent stalls, token expiry, 401 recovery, resume ids,
  reachability, and app pause/resume.
- `QuoteBook` tests cover duplicates, old ticks, equal timestamps, bounded
  deduplication, conflation and history.
- Parser tests cover SSE framing, chunk boundaries, comments and malformed
  payloads.
- Widget tests verify that a 220-tick burst does not rebuild a row above its
  price leaf, and that the status wording does not present stale prices as live.

Testing and running against the supplied server found a few real issues during
development: equal timestamps in bursts, an invisible flash animation, clearing
connection metadata too early during teardown, and an instrument-list error
screen that did not recover when the feed did.

## Scope I left out

Things I would do next, roughly in the order I would do them.

- No sanity check on tick timestamps. A tick dated far in the future would set
  that symbol's ordering watermark to a value nothing can beat, and every later
  tick would be silently rejected as stale. This server never does it, but the
  guard is a couple of lines and the failure mode is permanent and invisible.
- The instrument list is fetched once per session. It reloads if the feed
  recovers from a failed load, but nothing refreshes it otherwise, so a symbol
  added server-side never shows up until the app restarts.
- Direction is carried by colour alone. There is no arrow on the price and no
  semantic label, so a colour-blind user sees a flash with no direction and a
  screen reader gets nothing useful out of the row.
- No way to force a reconnect. Reachability covers the usual case, but if the
  client is midway through a 15s backoff the user cannot say "try now". A tap
  target on the banner would be enough.
- Prices are formatted with toStringAsFixed, so US30 reads 40211.0 rather than
  40,211.0. Locale-aware formatting would also fix the decimal separator.
- Session high/low is really "since app launch", and I have labelled it as
  session. A real client would anchor it to the trading session and persist it.
- The diagnostics counters ship in the release build. They earn their place
  while this is being reviewed; in a real app they belong behind a debug flag.

## Known limitations

- Frame timing is now measured in profile mode on a physical iPhone 16 Pro Max
  (iOS 26.6.1) against the chaotic server: 58,973 frames over ten minutes, build
  p50 0.7ms / p95 2.2ms, raster p50 0.8ms / p95 0.9ms. Exactly one frame went
  over 16.7ms and it was app launch; the worst after that was 5.7ms, inside the
  8.3ms budget the device actually has at 120Hz. The recorder is
  `lib/core/frame_report.dart` and only runs in profile builds, because DevTools'
  chart shows a rolling window of recent frames and cannot give a p95 over the
  whole run.
- Those numbers only hold with the profiler detached. An earlier run showed an
  isolated 35-46ms build frame once or twice a minute, and it was the tooling
  rather than the app: the reconnect path does not explain it (the instrument
  reload is guarded by `WatchlistFailed`, so an ordinary reconnect rebuilds
  nothing), nor does allocation pressure from the per-flush map (the VM service
  reported 1,477 collections, every one idle-reason and about a millisecond),
  and the spikes appeared only in the run where DevTools was attached and being
  driven.
- The stale marker is based only on elapsed time. An instrument that naturally
  trades infrequently can be marked stale even when the connection is healthy.
- The sparkline is based on conflated values rather than every raw tick.
- I developed against the default chaotic server and did not separately test
  `--calm` mode.

## AI use

I used Claude Code as a coding assistant for scaffolding, repetitive widget and
test code, and the Swift channel implementation. I made the architectural and
tradeoff decisions, read the supplied server to set the thresholds, and used the
running app and tests to validate the behaviour. In particular, the equal-
timestamp ordering issue and the lingering HTTP socket were found by inspecting
the real server behaviour rather than by generating more code.
