import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme/pulse_theme.dart';
import '../../core/app_config.dart';
import '../../core/clock.dart';
import '../../data/instruments/models/instrument.dart';
import '../../domain/models/price_cell.dart';
import '../blocs/price/price_bloc.dart';
import '../blocs/price/price_state.dart';
import '../widgets/connection_banner.dart';
import '../widgets/sparkline.dart';

/// Session high/low and a sparkline for one instrument.
///
/// Selects the same symbol out of the same [PriceBloc] the rows use, so
/// opening this screen costs one more selector - not a second data path.
class InstrumentDetailScreen extends StatelessWidget {
  const InstrumentDetailScreen({
    required this.instrument,
    required this.config,
    required this.clock,
    super.key,
  });

  final Instrument instrument;
  final AppConfig config;
  final Clock clock;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(instrument.symbol),
        backgroundColor: PulseColors.surfaceRaised,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ConnectionBanner(clock: clock),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              instrument.name,
              style: const TextStyle(color: PulseColors.textSecondary),
            ),
          ),
          Expanded(
            child: BlocSelector<PriceBloc, PriceState, PriceCell>(
              selector: (PriceState state) => state.cellFor(instrument.symbol),
              builder: (BuildContext context, PriceCell cell) {
                // Read on demand rather than carried in state - see
                // PriceBloc.historyFor.
                final SymbolHistory history =
                    context.read<PriceBloc>().historyFor(instrument.symbol);

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          _Figure(
                            label: 'BID',
                            value: _format(cell.bid),
                            emphasised: true,
                          ),
                          const SizedBox(width: 24),
                          _Figure(label: 'ASK', value: _format(cell.ask)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: <Widget>[
                          _Figure(
                            label: 'SESSION HIGH',
                            value: _format(history.high),
                            color: PulseColors.up,
                          ),
                          const SizedBox(width: 24),
                          _Figure(
                            label: 'SESSION LOW',
                            value: _format(history.low),
                            color: PulseColors.down,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'LAST ${history.recent.length} TICKS',
                        style: const TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 0.6,
                          color: PulseColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 140,
                        child: Sparkline(values: history.recent),
                      ),
                      const Spacer(),
                      if (cell.isStale)
                        const Text(
                          'No update for this instrument recently.',
                          style: TextStyle(
                            color: PulseColors.degraded,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _format(double? value) =>
      value == null ? '-' : value.toStringAsFixed(instrument.decimals);
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    this.color,
    this.emphasised = false,
  });

  final String label;
  final String value;
  final Color? color;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 0.6,
              color: PulseColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: kPriceTextStyle.copyWith(
              fontSize: emphasised ? 26 : 20,
              color: color ?? PulseColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
