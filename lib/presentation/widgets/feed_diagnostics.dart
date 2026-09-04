import 'package:flutter/material.dart';

import '../../app/theme/pulse_theme.dart';
import '../../data/feed/price_cell.dart';
import '../../data/feed/price_store.dart';

/// A one-line readout of what the feed threw at us and what we did about it.
///
/// Here because "we handle duplicates and out-of-order ticks" is a claim; a
/// counter that climbs while the app stays smooth is evidence. Updates once
/// per conflation window, never per tick.
class FeedDiagnostics extends StatelessWidget {
  const FeedDiagnostics({required this.store, super.key});

  final PriceStore store;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FeedStats>(
      valueListenable: store.stats,
      builder: (BuildContext context, FeedStats stats, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: PulseColors.surfaceRaised,
          child: Text(
            'applied ${stats.accepted}   '
            'duplicates ${stats.duplicates}   '
            'out-of-order ${stats.outOfOrder}   '
            'malformed ${stats.malformed}',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10.5,
              color: PulseColors.textSecondary,
            ),
          ),
        );
      },
    );
  }
}
