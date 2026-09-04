/// Every tunable in one place.
///
/// The thresholds below are derived from the feed server's actual behaviour:
/// heartbeats every 5s, silent stalls lasting exactly 25s, hard disconnects at
/// 25-55s, 60s token TTL, and a 1000-event replay buffer. See NOTES.md.
class AppConfig {
  const AppConfig({
    this.baseUrl = 'http://127.0.0.1:8080',
    this.username = 'trader',
    this.password = 'password123',
    this.stallDegradedAfter = const Duration(seconds: 8),
    this.stallReconnectAfter = const Duration(seconds: 12),
    this.backoffBase = const Duration(milliseconds: 500),
    this.backoffCap = const Duration(seconds: 15),
    this.backoffJitter = 0.2,
    this.backoffResetAfterHealthy = const Duration(seconds: 10),
    this.tokenRefreshLead = const Duration(seconds: 15),
    this.tokenExpiryGrace = const Duration(seconds: 5),
    this.expectedDropWindow = const Duration(seconds: 2),
    this.conflationInterval = const Duration(milliseconds: 16),
    this.dedupWindow = 2048,
    this.flashDuration = const Duration(milliseconds: 400),
    this.staleBadgeAfter = const Duration(seconds: 8),
    this.sparklineDepth = 120,
  });

  final String baseUrl;

  /// Pre-filled on the login form. The server only accepts this pair.
  final String username;
  final String password;

  /// Silence (no ticks *and* no heartbeats) before the UI stops claiming "live".
  final Duration stallDegradedAfter;

  /// Silence before we give up on the socket and reconnect. Deliberately well
  /// under the server's 25s stall so we never ride a freeze out.
  final Duration stallReconnectAfter;

  final Duration backoffBase;
  final Duration backoffCap;

  /// Fraction of the delay applied as +/- jitter, e.g. 0.2 => +/-20%.
  final double backoffJitter;

  /// How long a stream must stay healthy before backoff resets to base.
  final Duration backoffResetAfterHealthy;

  /// Refresh the token this long before it expires (TTL is 60s).
  final Duration tokenRefreshLead;

  /// Treat a token as already dead this long before its real expiry.
  final Duration tokenExpiryGrace;

  /// A drop this close to a known token expiry is "expected" and reconnects
  /// with zero backoff instead of costing a backoff step every minute.
  final Duration expectedDropWindow;

  /// Coalescing window for incoming ticks. Frame-aligned.
  final Duration conflationInterval;

  /// How many recent event ids we remember for duplicate suppression.
  final int dedupWindow;

  final Duration flashDuration;

  /// A symbol with no tick for this long is badged as stale.
  final Duration staleBadgeAfter;

  /// Ring-buffer depth per symbol for the detail sparkline.
  final int sparklineDepth;

  Uri endpoint(String path) => Uri.parse('$baseUrl$path');
}
