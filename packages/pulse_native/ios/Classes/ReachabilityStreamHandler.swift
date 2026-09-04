import Flutter
import Foundation
import Network

/// Bridges `NWPathMonitor` to an EventChannel.
///
/// `NWPathMonitor` invokes its update handler once with the current path as
/// soon as it starts, so subscribers get today's state immediately rather than
/// waiting for the network to change.
class ReachabilityStreamHandler: NSObject, FlutterStreamHandler {
  private var monitor: NWPathMonitor?
  private let queue = DispatchQueue(label: "pulse_native.reachability")

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    let monitor = NWPathMonitor()
    self.monitor = monitor

    monitor.pathUpdateHandler = { path in
      let payload = ReachabilityStreamHandler.payload(for: path)
      // Channel sinks must be touched from the platform thread.
      DispatchQueue.main.async {
        events(payload)
      }
    }

    monitor.start(queue: queue)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    monitor?.cancel()
    monitor = nil
    return nil
  }

  private static func payload(for path: NWPath) -> [String: Any] {
    let online = path.status == .satisfied
    return [
      "online": online,
      "interface": interfaceName(for: path, online: online),
      "expensive": path.isExpensive,
    ]
  }

  private static func interfaceName(for path: NWPath, online: Bool) -> String {
    guard online else { return "none" }
    if path.usesInterfaceType(.wifi) { return "wifi" }
    if path.usesInterfaceType(.cellular) { return "cellular" }
    if path.usesInterfaceType(.wiredEthernet) { return "wired" }
    return "other"
  }
}
