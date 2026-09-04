import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme/pulse_theme.dart';
import '../../core/clock.dart';
import '../blocs/feed/feed_connection_bloc.dart';
import '../blocs/feed/feed_state.dart';

/// The answer to "can I trust these numbers right now?".
///
/// Ticks its own countdown once a second rather than making the bloc emit a
/// state per second: the bloc's state already carries the two timestamps, and
/// re-rendering one small widget is cheaper than waking the whole tree.
class ConnectionBanner extends StatefulWidget {
  const ConnectionBanner({required this.clock, super.key});

  final Clock clock;

  @override
  State<ConnectionBanner> createState() => _ConnectionBannerState();
}

class _ConnectionBannerState extends State<ConnectionBanner> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeedConnectionBloc, FeedState>(
      builder: (BuildContext context, FeedState state) {
        final (Color color, String label) = _describe(state);

        return Container(
          width: double.infinity,
          color: color.withValues(alpha: 0.14),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (state.gapCount > 0)
                Tooltip(
                  message: 'Reconnected past the server\'s replay buffer: '
                      'some ticks are gone for good.',
                  child: Text(
                    '${state.gapCount} gap${state.gapCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: PulseColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  (Color, String) _describe(FeedState state) {
    final DateTime now = widget.clock.now();

    return switch (state.phase) {
      ConnectionPhase.idle => (PulseColors.connecting, 'Idle'),
      ConnectionPhase.connecting => (PulseColors.connecting, 'Connecting...'),
      ConnectionPhase.live => (PulseColors.live, 'Live'),
      ConnectionPhase.degraded => (
          PulseColors.degraded,
          'Stalled - no data for ${_secondsSince(state.silentSince, now)}s. '
              'Prices below are not current.',
        ),
      ConnectionPhase.reconnecting => (
          PulseColors.reconnecting,
          'Reconnecting in ${_secondsUntil(state.nextAttemptAt, now)}s '
              '(attempt ${state.attempt})',
        ),
      ConnectionPhase.offline => (
          PulseColors.offline,
          'Device offline - not retrying until the network returns',
        ),
      ConnectionPhase.authFailed => (
          PulseColors.offline,
          state.message ?? 'Authentication failed',
        ),
    };
  }

  String _secondsSince(DateTime? since, DateTime now) =>
      since == null ? '?' : now.difference(since).inSeconds.clamp(0, 999).toString();

  String _secondsUntil(DateTime? until, DateTime now) => until == null
      ? '?'
      : (until.difference(now).inMilliseconds / 1000).ceil().clamp(0, 999).toString();
}
