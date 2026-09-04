# Pulse

A live market watchlist over an intentionally hostile SSE feed: random
disconnects, silent stalls, bursts, duplicates, out-of-order ticks, malformed
payloads, and 60-second tokens.

See **[NOTES.md](NOTES.md)** for design decisions, tradeoffs, and known gaps.

---

## Requirements

| | |
|---|---|
| Flutter | **3.41.1** (stable) |
| Dart | **3.11.0** |
| Native piece targets | **iOS** (Keychain + `NWPathMonitor`) |
| Xcode | 26.x, for the iOS build |

Verified on the iOS Simulator (iPhone 16 Pro, iOS 18.6).

## Running it

**1. Start the feed server** (chaotic mode - this is what the app is built
against):

```bash
dart run tool/feed_server.dart
```

`--calm` disables the misbehaviour, `--port N` and `--seed N` are also
available. The server is vendored here so everything runs from one checkout.

**2. Run the app** on an iOS simulator:

```bash
flutter pub get && flutter run
```

Sign in with the pre-filled `trader` / `password123`. You are asked exactly
once - credentials go to the Keychain and every later launch restores silently.

### Running on a physical device

The simulator shares the host's network stack, so the default
`http://127.0.0.1:8080` works there. A real device needs the Mac's LAN address:

```bash
flutter run --dart-define=PULSE_BASE_URL=http://192.168.1.10:8080
```

Replace the IP with your Mac's (`ipconfig getifaddr en0`). Also required:

- the phone and Mac on the same Wi-Fi;
- **Allow** on the iOS local-network permission prompt at first launch;
- macOS must accept incoming connections to `dart` (System Settings → Network →
  Firewall). If the firewall blocks all incoming connections, the phone cannot
  reach the server and the app will sit in its reconnect loop.

## Tests

```bash
flutter test && (cd packages/pulse_native && flutter test)
```

95 tests in the app, 11 in the plugin. Connection-lifecycle logic is tested
against a fake transport and `fake_async` - no real server, no real time. See
NOTES.md §8 for what is covered and why.

## Regenerating code

`freezed`, `json_serializable` and `injectable` outputs are committed so the app
builds without a codegen step. After changing a model, event, state, or an
injectable annotation:

```bash
dart run build_runner build
```

## Layout

```
lib/
  core/          AppConfig (every tunable), Clock, PeriodicTicker, error types
  domain/        ports (SecureStore, NetworkMonitor, TickSink), models,
                 ReconnectPolicy
  data/
    auth/        login, token lifecycle, Keychain persistence
    feed/        SSE parser + transport, tick codec, QuoteBook
    instruments/ instrument list
    platform/    adapters onto the native plugin
  presentation/
    blocs/       AuthBloc, FeedConnectionBloc, PriceBloc, WatchlistBloc
    screens/     login, watchlist, instrument detail
    widgets/     price row, connection banner, diagnostics, sparkline
packages/
  pulse_native/  the iOS plugin (MethodChannel + EventChannel)
tool/
  feed_server.dart
```

## Where to look first

- `lib/presentation/blocs/feed/feed_connection_bloc.dart` - the resilience state
  machine.
- `lib/presentation/blocs/price/price_bloc.dart` - the data plane: conflation,
  and the copy-on-write map that keeps `BlocSelector` cheap.
- `lib/data/feed/quote_book.dart` - dedup and `(ts, id)` ordering, pure.
- `lib/core/app_config.dart` - every threshold in one place, with the reasoning.
