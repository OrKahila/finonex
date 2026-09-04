import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/theme/pulse_theme.dart';
import '../../core/app_config.dart';
import '../../data/feed/price_cell.dart';
import '../../data/instruments/models/instrument.dart';

/// One instrument.
///
/// The symbol and name are built once and never again. Only the price pair
/// listens to the store, so a tick rebuilds a single leaf - not the row, not
/// the list. [RepaintBoundary] keeps a flashing row from repainting its
/// neighbours.
class PriceRow extends StatelessWidget {
  const PriceRow({
    required this.instrument,
    required this.listenable,
    required this.config,
    this.onTap,
    super.key,
  });

  final Instrument instrument;
  final ValueListenable<PriceCell> listenable;
  final AppConfig config;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: PulseColors.divider, width: 0.5),
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      instrument.symbol,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      instrument.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PulseColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 6,
                child: ValueListenableBuilder<PriceCell>(
                  valueListenable: listenable,
                  builder: (BuildContext context, PriceCell cell, _) {
                    return FlashingPrices(
                      cell: cell,
                      decimals: instrument.decimals,
                      flashDuration: config.flashDuration,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bid and ask, with a background wash on change.
///
/// The animation is keyed off [PriceCell.revision], which the store only
/// increments when the displayed price actually moved. A duplicate event, or
/// a re-delivery of the same price, therefore cannot produce a second flash.
class FlashingPrices extends StatefulWidget {
  const FlashingPrices({
    required this.cell,
    required this.decimals,
    required this.flashDuration,
    super.key,
  });

  final PriceCell cell;
  final int decimals;
  final Duration flashDuration;

  @override
  State<FlashingPrices> createState() => _FlashingPricesState();
}

class _FlashingPricesState extends State<FlashingPrices>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.flashDuration,
  );

  @override
  void didUpdateWidget(FlashingPrices oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool moved = widget.cell.revision != oldWidget.cell.revision;
    if (moved && widget.cell.direction != PriceDirection.none) {
      // Runs 0 -> 1 while the wash fades 1 -> 0, so the row lights up on the
      // move and settles back.
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PriceCell cell = widget.cell;
    final Color wash = switch (cell.direction) {
      PriceDirection.up => PulseColors.upWash,
      PriceDirection.down => PulseColors.downWash,
      PriceDirection.none => Colors.transparent,
    };

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: wash.withValues(alpha: wash.a * (1 - _controller.value)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            if (cell.isStale)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.schedule,
                  size: 12,
                  color: PulseColors.degraded,
                ),
              ),
            Expanded(child: _price(cell.bid, cell.direction, isBid: true)),
            const SizedBox(width: 12),
            Expanded(child: _price(cell.ask, cell.direction, isBid: false)),
          ],
        ),
      ),
    );
  }

  Widget _price(double? value, PriceDirection direction, {required bool isBid}) {
    final Color color = switch (direction) {
      PriceDirection.up => PulseColors.up,
      PriceDirection.down => PulseColors.down,
      PriceDirection.none => PulseColors.textPrimary,
    };

    return Text(
      value == null ? '-' : value.toStringAsFixed(widget.decimals),
      textAlign: TextAlign.right,
      style: kPriceTextStyle.copyWith(
        color: value == null ? PulseColors.textSecondary : color,
        fontWeight: isBid ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}
