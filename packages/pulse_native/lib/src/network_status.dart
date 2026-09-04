/// The transport the device is currently using, as reported by the platform.
enum NetworkInterfaceKind { wifi, cellular, wired, other, none }

/// A snapshot of device reachability.
///
/// Value type on purpose: it crosses a channel boundary and is compared for
/// equality by the reconnect logic, which must not react to identical repeats.
class NetworkStatus {
  const NetworkStatus({
    required this.isOnline,
    required this.interface,
    required this.isExpensive,
  });

  /// Used before the platform has reported anything, and by platforms without
  /// a native implementation. Assuming "online" is the safe default: it lets
  /// the reconnect logic try, and a failed attempt is cheap. Assuming
  /// "offline" would wedge the app shut.
  static const NetworkStatus assumedOnline = NetworkStatus(
    isOnline: true,
    interface: NetworkInterfaceKind.other,
    isExpensive: false,
  );

  static const NetworkStatus offline = NetworkStatus(
    isOnline: false,
    interface: NetworkInterfaceKind.none,
    isExpensive: false,
  );

  factory NetworkStatus.fromMap(Map<Object?, Object?> map) {
    return NetworkStatus(
      isOnline: map['online'] as bool? ?? false,
      interface: _kindFromName(map['interface'] as String?),
      isExpensive: map['expensive'] as bool? ?? false,
    );
  }

  final bool isOnline;
  final NetworkInterfaceKind interface;

  /// True on cellular or personal hotspot. Not used for reconnect decisions
  /// today; exposed because a real client would back off harder on it.
  final bool isExpensive;

  static NetworkInterfaceKind _kindFromName(String? name) {
    return switch (name) {
      'wifi' => NetworkInterfaceKind.wifi,
      'cellular' => NetworkInterfaceKind.cellular,
      'wired' => NetworkInterfaceKind.wired,
      'none' => NetworkInterfaceKind.none,
      _ => NetworkInterfaceKind.other,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkStatus &&
          other.isOnline == isOnline &&
          other.interface == interface &&
          other.isExpensive == isExpensive;

  @override
  int get hashCode => Object.hash(isOnline, interface, isExpensive);

  @override
  String toString() =>
      'NetworkStatus(online: $isOnline, interface: ${interface.name}, '
      'expensive: $isExpensive)';
}
