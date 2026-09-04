import Flutter
import Foundation

public class PulseNativePlugin: NSObject, FlutterPlugin {
  private let store: KeychainStore

  /// Held so ARC does not release the handler the moment `register` returns.
  private static var reachabilityHandler: ReachabilityStreamHandler?

  override init() {
    store = KeychainStore(
      service: Bundle.main.bundleIdentifier ?? "com.pulse.pulseNative"
    )
    super.init()
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = PulseNativePlugin()

    let methodChannel = FlutterMethodChannel(
      name: "pulse_native/secure_storage",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(instance, channel: methodChannel)

    let handler = ReachabilityStreamHandler()
    reachabilityHandler = handler
    let eventChannel = FlutterEventChannel(
      name: "pulse_native/reachability",
      binaryMessenger: registrar.messenger()
    )
    eventChannel.setStreamHandler(handler)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    do {
      switch call.method {
      case "write":
        guard let key = argument(call, "key"), let value = argument(call, "value") else {
          result(Self.badArguments(call.method))
          return
        }
        try store.write(key: key, value: value)
        result(nil)

      case "read":
        guard let key = argument(call, "key") else {
          result(Self.badArguments(call.method))
          return
        }
        result(try store.read(key: key))

      case "delete":
        guard let key = argument(call, "key") else {
          result(Self.badArguments(call.method))
          return
        }
        try store.delete(key: key)
        result(nil)

      case "deleteAll":
        try store.deleteAll()
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    } catch KeychainStore.StoreError.unexpectedStatus(let status) {
      result(
        FlutterError(
          code: "keychain_error",
          message: "Keychain operation failed with OSStatus \(status)",
          details: Int(status)
        )
      )
    } catch {
      result(
        FlutterError(
          code: "unknown_error",
          message: error.localizedDescription,
          details: nil
        )
      )
    }
  }

  private func argument(_ call: FlutterMethodCall, _ name: String) -> String? {
    (call.arguments as? [String: Any])?[name] as? String
  }

  private static func badArguments(_ method: String) -> FlutterError {
    FlutterError(
      code: "bad_arguments",
      message: "Missing or malformed arguments for \(method)",
      details: nil
    )
  }
}
