# Pulse — Implementation Plan

Live market watchlist over a deliberately hostile SSE feed.
Target: Flutter 3.41.1 / Dart 3.11.0, native piece on **iOS**.

> This file is a working document for the build, not a graded deliverable.
> `NOTES.md` (decisions, cuts, gaps, AI usage) is the deliverable. Delete or keep
> `PLAN.md` before submitting — keeping it is fine and shows process.

---

## 0. Decisions already made

| # | Decision |
|---|---|
| Scope | Build the full thing; no artificial cuts. `NOTES.md` still gets an honest "what I'd do next / known gaps" section. |
| Repo | `git init` in `/Users/or/finonex`, package stays `finonex`. Real incremental commits, authored as the user, no AI co-author trailer. |
| Server | Vendored at `tool/feed_server.dart` so graders run everything from one checkout. |
| Style | Boring, readable, few abstractions. Every line must be defensible verbally in a 45–60 min call. |
| Native | iOS only. **Local plugin package** `packages/pulse_native` (Swift: Keychain + `NWPathMonitor`). |
| Second platform | Not implemented. Dart side uses the standard federated shape (`PulseNativePlatform` abstract + `MethodChannelPulseNative` default instance) so Android slots in by registering another implementation. A pure-Dart `InMemoryPulseNative` fallback keeps the app runnable on non-iOS. |
| Auth persistence | Username/password **and** token go to Keychain via our own channel. After the first successful login the user is never prompted again — cold start re-logs in silently. Security tradeoff documented in `NOTES.md`. |
| State | Option (A): app-level BLoCs own the **control plane**; a `PriceStore` of per-symbol `ValueNotifier`s owns the **data plane**. One tick rebuilds one leaf widget; the list widget never rebuilds. |
| DI | `get_it` + `injectable`. |
| Models | `freezed` for states/events/DTOs; **hand-written** parsing for the tick hot path. |

---

## 1. What reading `feed_server.dart` pins down

Numbers the assignment leaves vague, taken from the server source. These justify
every threshold below and are the kind of thing the follow-up call will probe.

- Heartbeat `: ping` every **5s** on a healthy connection.
- Stall: `conn.stalled = true` at a random 15–45s, cleared exactly **25s** later. Socket stays open, zero bytes flow.
- Hard disconnect: scheduled once per connection at **25–55s**.
- Token TTL **60s**; a per-connection 1s timer closes the stream the moment the token expires. So *every* connection dies at ≤60s regardless.
- Replay buffer holds the last **1000 events**. Reconnect with `Last-Event-ID`: replay if `lastId >= buffer.first.id - 1`, otherwise one `event: gap` and continue live.
- Burst: **220 ticks** synchronously, drawn from the 4 `rate == 0` symbols (EURUSD, GBPUSD, XAUUSD, US500, BTCUSD).
- Duplicate: a byte-identical replay of a buffered event — **same `id`**.
- Out-of-order: `emit(prevPrice, lastTs - 3000)` — a **new, higher `id`** carrying a 3s-old `ts`. ID dedup cannot catch this; only a per-symbol `ts` guard can.
- Malformed: `data: ###garbage-not-json###` with **no `id:` and no `event:` field**.
- Normal tick rate: ~4 hot symbols at 80%/100ms plus ~36 others at 12%/2% → roughly 60–90 ticks/sec baseline.

---

## 2. Architecture

Two planes, and the split is the central design story:

**Control plane (BLoCs, pure Dart, no Flutter widgets):** connection lifecycle,
backoff, stall detection, token refresh, reachability, instrument loading.
Low-frequency, event-sourced, fully unit-testable with `fake_async`.

**Data plane (`PriceStore`):** 60–90 ticks/sec baseline, 220-tick bursts.
Never routed through bloc state — that would rebuild the tree at tick rate.
Ticks are dedup'd, ordered, conflated, then written into a per-symbol
`ValueNotifier<PriceCell>`. Each row widget listens to exactly one notifier.

```
SSE bytes ──▶ SseParser ──▶ SseEvent ──▶ TickCodec ──▶ FeedConnectionBloc
                                                          │  (control: state machine)
                                                          ▼
                                                      PriceStore
                                              (dedup → order → conflate)
                                                          │
                                          ValueNotifier<PriceCell> per symbol
                                                          │
                                                    PriceRow leaf widget
```

### File layout

```
lib/
  main.dart
  app/
    app.dart                     MaterialApp, routes, theme
    di/injector.dart             get_it + injectable @InjectableInit
    di/register_module.dart      HttpClient, Random, Clock, PulseNativePlatform selection
    theme/pulse_theme.dart
  core/
    clock.dart                   Clock (systemClock / fake in tests)
    app_config.dart              ALL tunable constants in one place
    logging.dart
  data/
    auth/
      auth_api.dart              POST /login
      auth_repository.dart       token lifecycle, Keychain, silent re-login
      models/session.freezed.dart
    instruments/
      instruments_api.dart       GET /instruments
      models/instrument.dart     freezed + json_serializable
    feed/
      sse/sse_event.dart         raw {id, event, data} — freezed
      sse/sse_parser.dart        pure line→event parser (no IO)
      sse/sse_transport.dart     abstract: connect(token, lastEventId) → Stream<SseEvent>
      sse/http_sse_transport.dart  dart:io HttpClient impl
      tick.dart                  Tick {symbol, bid, ask, ts, eventId} — hand-parsed
      tick_codec.dart            SseEvent → Tick? (returns null on garbage)
      price_store.dart           dedup + ordering + conflation + ValueNotifiers
      price_cell.dart            {bid, ask, direction, ts, flashSeq, isStale}
      conflation_scheduler.dart  abstract flush tick source (frame-tied / fake)
  domain/
    connection_status.dart       freezed union: connecting | live | degraded | reconnecting | offline | authFailed
    reconnect_policy.dart        pure backoff calculator (base, cap, jitter, reset)
    network_monitor.dart         app-facing reachability port
    token_storage.dart           app-facing secure-storage port
  presentation/
    blocs/auth/                  AuthBloc      (login form, session bootstrap)
    blocs/feed/                  FeedConnectionBloc (the state machine)
    blocs/watchlist/             WatchlistBloc (instrument list, load/error/order)
    screens/login_screen.dart
    screens/watchlist_screen.dart
    screens/instrument_detail_screen.dart      (stretch)
    widgets/connection_banner.dart
    widgets/price_row.dart                     ValueListenableBuilder + RepaintBoundary
    widgets/flash_price.dart                   leaf flash animation
    widgets/sparkline.dart                     (stretch) CustomPainter
packages/pulse_native/
  lib/pulse_native.dart          PulseNativePlatform (abstract) + models
  lib/src/method_channel_pulse_native.dart
  lib/src/in_memory_pulse_native.dart          non-iOS fallback
  ios/Classes/PulseNativePlugin.swift          MethodChannel + EventChannel
  ios/Classes/KeychainStore.swift
  ios/Classes/ReachabilityStreamHandler.swift  NWPathMonitor
tool/feed_server.dart
test/  (mirrors lib/)
NOTES.md
```

### BLoC responsibilities

- **AuthBloc** — login form submit, credential persistence, bootstrap on cold start
  (creds in Keychain → silent login → never prompt again), logout.
- **FeedConnectionBloc** — the resilience state machine. Owns: connect, stall
  watchdog, backoff timers, reachability gating, token refresh, `Last-Event-ID`,
  gap notices. Emits `ConnectionStatus` only (a handful of events/sec at most).
  Ticks are side-effected into `PriceStore`.
- **WatchlistBloc** — fetch `/instruments`, hold the ordered symbol list, retry on
  401 via AuthRepository, expose display metadata (name, decimals).

None of these are Cubits; all transitions go through explicit events.

---

## 3. Resilience state machine (FeedConnectionBloc)

States: `Connecting` · `Live` · `Degraded(silentFor)` · `Reconnecting(attempt, nextAttemptIn)` · `Offline` · `AuthFailed`

Events: `Started` · `TokenReady` · `StreamOpened` · `BytesReceived` · `TickReceived` · `GapReceived` · `StreamClosed(reason)` · `StallTimerFired` · `ReconnectTimerFired` · `ReachabilityChanged` · `TokenRefreshed` · `Stopped`

### Rules

1. **Stall watchdog** — a timer reset on *any* inbound bytes (tick **or** `: ping` comment).
   - 8s of silence → `Degraded`. Banner turns amber, rows dim, prices marked stale.
   - 12s of silence → tear the socket down and reconnect. We never ride out the server's 25s freeze.
2. **Backoff** — 500ms base, ×2, cap **15s**, ±20% jitter from an injected `Random`.
   Reset to base after **10s** of continuously healthy stream.
3. **Expected drops** — the server kills every connection at token expiry. If we
   dropped within ~2s of a known token expiry *and* we already hold a fresh token,
   reconnect immediately with **zero** backoff. That keeps the 60s token cycle
   invisible instead of costing a backoff step every minute.
4. **Reachability gate** — `NetworkMonitor` offline → cancel pending reconnect,
   enter `Offline`, stop all attempts. Back online → reset backoff and attempt at once.
5. **Resume** — always send `Last-Event-ID: <highest id seen>`. On `event: gap`,
   emit a transient "reconnected — some ticks skipped" notice.
6. **401 handling** — a 401 on connect forces a token refresh, then one immediate
   retry. Two consecutive 401s after a successful refresh → `AuthFailed` (only path
   back to the login screen).
7. **Malformed** — `TickCodec` returns null, a counter increments, the stream lives.

### Token lifecycle (AuthRepository)

- Proactive refresh timer at **45s** (TTL 60s). Fresh token is ready before the
  server drops us, so the reconnect at ~60s is instant and login-free.
- Reactive: any 401 triggers a refresh using Keychain-stored credentials.
- `getValidToken()` refreshes if the token expires within 5s.

### Constants (all in `core/app_config.dart`, one object, easy to tune live)

| Name | Value |
|---|---|
| `baseUrl` | `http://127.0.0.1:8080` |
| `stallDegradedAfter` | 8s |
| `stallReconnectAfter` | 12s |
| `backoffBase` / `backoffCap` / `backoffJitter` | 500ms / 15s / ±20% |
| `backoffResetAfterHealthy` | 10s |
| `tokenRefreshLead` | 15s (refresh at t+45 of a 60s TTL) |
| `conflationInterval` | 16ms (frame-aligned) |
| `dedupWindow` | 2048 event ids |
| `flashDuration` | 400ms |
| `staleBadgeAfter` | 8s since last tick for that symbol |

---

## 4. Correctness pipeline (PriceStore)

Three ordered filters, each independently unit-tested:

1. **Dedup by event id** — LRU ring of the last 2048 ids. Catches the server's
   byte-identical replays. O(1), bounded memory.
2. **Per-symbol monotonic `ts` guard** — drop if `tick.ts <= lastTs[symbol]`.
   This is what catches the `ts - 3000` out-of-order events, which carry a *new*
   id and so pass step 1. Equal `ts` is dropped (treated as a replay) — cheap, and
   it removes a whole class of double-flash artifacts.
3. **Conflation** — accepted ticks land in a `Map<String, Tick>` (last-write-wins
   per symbol), flushed on a frame-aligned scheduler (16ms). A 220-tick burst across
   5 symbols becomes **≤5 notifier writes on the next frame**, so it costs the same
   as 5 ordinary ticks. Flash direction is computed on the **net** move across the
   window, so bursts and duplicates produce at most one flash per symbol per frame.

`PriceCell` carries `{bid, ask, direction, ts, flashSeq}`. `flashSeq` only
increments when the price actually changed, so an identical re-delivery can't
retrigger the animation.

`ConflationScheduler` is an interface: frame-tied in the app, manually pumped in
tests. Keeps the store deterministic without real time.

---

## 5. UI

**Login** — real form, pre-filled `trader` / `password123`, inline error on 401,
loading state. Shown exactly once in the app's lifetime (afterwards Keychain
credentials bootstrap silently).

**Watchlist** — `ListView.builder` over instrument symbols. The builder closes over
a `ValueNotifier` looked up by symbol; the list itself is `const`-stable and never
rebuilds on ticks. Each row: `RepaintBoundary` → `ValueListenableBuilder` →
`FlashPrice` leaf. Bid/ask formatted to the instrument's `decimals`.

**Connection banner** — always visible, driven by `FeedConnectionBloc`:
- `connecting` grey · `live` green · `degraded` amber ("no data for Ns")
- `reconnecting` orange with attempt number and countdown · `offline` red ("device offline")
- gap notice as a transient snackbar.

Anti-frozen-price rule (their hard requirement): when status is anything but
`live`, rows dim, the price colour desaturates, and any symbol with no tick for
>8s shows an age badge. There is no state in which stale numbers look live.

**Detail screen (stretch)** — session high/low and a `CustomPainter` sparkline over
a bounded ring buffer of recent ticks, fed by the same notifier.

---

## 6. Native plugin — `packages/pulse_native` (iOS)

**MethodChannel** `pulse_native/secure_storage`
- `write(key, value)` · `read(key) → String?` · `delete(key)` · `deleteAll()`
- Swift: `SecItemAdd`/`CopyMatching`/`Update`/`Delete` on `kSecClassGenericPassword`,
  accessibility `kSecAttrAccessibleAfterFirstUnlock`, service = bundle id.
- Errors surface as `FlutterError` with stable codes; Dart maps them to a typed
  `SecureStorageException`.
- Keys used: `pulse.token`, `pulse.token_expiry`, `pulse.username`, `pulse.password`.

**EventChannel** `pulse_native/reachability`
- `NWPathMonitor` on a background queue → `{"online": bool, "interface": "wifi|cellular|wired|other|none", "expensive": bool}`.
- Emits current state immediately on listen (no "unknown" gap at startup), then on change.
- Cancels the monitor on `onCancel`.

**Dart API** — `PulseNativePlatform` abstract class with a swappable
`PulseNativePlatform.instance`, the standard federated shape. Adding Android means
adding one implementation and registering it; nothing in the app changes.
`InMemoryPulseNative` (in-memory map + always-online) is registered on non-iOS so
the app still runs, loudly logged and documented as a stub.

No `flutter_secure_storage`, no `connectivity_plus`.

---

## 7. Tests

Seven, deliberately chosen over coverage:

1. **`sse_parser_test`** — multi-line events, `id`/`event`/`data` fields, `: ping`
   comments, the exact garbage payload, split-across-chunk boundaries, CRLF.
2. **`tick_pipeline_test`** — duplicate id dropped; `ts - 3000` out-of-order dropped;
   equal `ts` dropped; newer tick accepted; per-symbol independence.
3. **`reconnect_backoff_test`** — `fake_async` + fake transport. Asserts the exact
   delay sequence with a seeded `Random`, the 15s cap, jitter bounds, reset after
   10s healthy, and zero-backoff on an expected token-expiry drop.
4. **`stall_detector_test`** — heartbeats keep it `Live`; 8s silence → `Degraded`;
   12s → reconnect; a `: ping` at 7s resets the watchdog.
5. **`token_expiry_test`** — mid-stream 401 → silent re-login → reconnect carries
   the new token and the correct `Last-Event-ID`; user is never prompted.
6. **`reachability_gating_test`** — offline suppresses reconnect attempts entirely
   (assert zero transport calls); back-online triggers an immediate attempt with
   backoff reset.
7. **`price_row_rebuild_test`** — widget test: pump 200 ticks, assert the list
   widget built once and only the affected rows rebuilt (build counters on
   instrumented widgets).

Tooling: `bloc_test`, `fake_async`, hand-written fakes (`FakeSseTransport`,
`FakeClock`, `FakeNetworkMonitor`, `FakeSecureStorage`). No real server, no real time.

---

## 8. Build order & commit plan

Each step is one or a few commits; the app compiles and passes tests at every step.

| # | Step | Commits |
|---|---|---|
| 0 | `git init`, `.gitignore`, vendor `tool/feed_server.dart`, deps, lints | 2–3 |
| 1 | `core/` (Clock, AppConfig), DI skeleton, theme, app shell | 2 |
| 2 | `packages/pulse_native`: Dart API + in-memory impl + iOS Swift (Keychain, NWPathMonitor); manual sim smoke test | 3–4 |
| 3 | Auth: api, repository, Keychain persistence, AuthBloc, login screen, bootstrap | 3 |
| 4 | SSE parser + transport + Tick codec **+ tests 1** | 2 |
| 5 | `FeedConnectionBloc` state machine: backoff, stall, reachability, token, resume **+ tests 3,4,5,6** | 4–5 |
| 6 | `PriceStore`: dedup, ordering, conflation **+ test 2** | 2 |
| 7 | Watchlist UI: list, rows, flash, banner, stale badges **+ test 7** | 3 |
| 8 | Chaos verification against the real server on the iOS simulator + DevTools frame/rebuild check | 1 |
| 9 | Stretch: detail screen + sparkline | 1–2 |
| 10 | `NOTES.md` + README run instructions | 1–2 |

Target ~22–28 commits with meaningful messages.

---

## 9. Verification

- Run `dart run tool/feed_server.dart` (chaotic default) and drive the app in the
  iOS simulator.
- Watch for: reconnect after each ~25–55s drop, amber degraded state during the
  25s stall, no double flashes, no backwards price ticks, silent token cycling at
  60s, survival of garbage payloads.
- DevTools: performance overlay + "Track widget builds" during a burst. Success
  criterion is frames staying under budget and the list widget's rebuild count
  staying flat while rows update.
- Airplane-mode toggle in the simulator to confirm reachability gating.
- Screenshots captured for `NOTES.md`.

---

## 10. NOTES.md contents (deliverable)

- The control-plane / data-plane split and why ticks bypass bloc state.
- Conflation at 16ms: why frame-aligned rather than a slower fixed rate, and what
  is lost (intermediate prices within a frame — irrelevant for a watchlist,
  relevant for a tape, which is why the detail screen keeps a ring buffer).
- What "no data loss" can and cannot mean: the server buffers 1000 events; at
  ~60–90 ticks/sec that is ~11–16 seconds of history. Any outage longer than that
  is unrecoverable by design and surfaces as `event: gap`. We show it rather than
  pretending continuity.
- Why the stall reconnect fires at 12s instead of waiting out the 25s freeze.
- Security tradeoff: credentials in the Keychain to satisfy "never prompt again"
  against a server with 60s tokens and no refresh-token endpoint. What a real
  system would do instead (refresh tokens, biometric gate).
- Known gaps and what I'd do next.
- AI tool usage.

---

## 11. Open risks

- `injectable` + `freezed` + `build_runner` on Dart 3.11 — pin versions early and
  run codegen in step 1 so a version conflict surfaces before it blocks anything.
- `fake_async` around bloc's async emit needs care; if it gets fragile, fall back
  to an injected `TimerFactory` rather than fighting the zone.
- Frame-aligned conflation must not starve: if the flush scheduler is driven by
  `SchedulerBinding` and the app is backgrounded, pending ticks must not accumulate
  unbounded — cap the pending map (it is already keyed by symbol, so it is bounded
  at ~40 entries by construction).
