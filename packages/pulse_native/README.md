# pulse_native

The one native piece of Pulse, targeting **iOS**.

| Channel | Name | Native |
|---|---|---|
| MethodChannel | `pulse_native/secure_storage` | Keychain (`kSecClassGenericPassword`) |
| EventChannel | `pulse_native/reachability` | `NWPathMonitor` |

No `flutter_secure_storage`, no `connectivity_plus` - this is hand-written
channel code.

## Dart API

`PulseNativePlatform.instance` is the single entry point. It is an abstract
class with a swappable static instance (the standard federated-plugin shape),
so adding Android later means writing one subclass over
`EncryptedSharedPreferences` + `ConnectivityManager` and selecting it in
`_defaultInstance()`. No caller changes.

`InMemoryPulseNative` is selected on every non-iOS platform so the app still
runs there. It is a stub, not secure storage, and it logs that fact.

## Secure storage notes

- Items are namespaced by service = the app's bundle id, so `deleteAll` cannot
  reach other apps' secrets.
- Accessibility is `kSecAttrAccessibleAfterFirstUnlock`: the feed keeps working
  with the screen locked, but nothing is readable before the first unlock after
  boot.
- Writes are update-then-add, so a key is never momentarily absent.
- `OSStatus` failures surface as `SecureStorageException` with a stable code;
  a missing plugin registration is reported separately as `unavailable`.

## Reachability notes

`NWPathMonitor` fires its update handler immediately on start, so the first
event a subscriber receives is the current state, not the next change. Events
are pushed to the sink on the main thread. `onCancel` tears the monitor down.
