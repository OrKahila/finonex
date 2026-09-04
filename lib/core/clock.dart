/// Wall-clock access behind an interface so time-dependent logic (token expiry,
/// stall detection, backoff) can be driven deterministically in tests.
abstract class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
