import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/di/injector.dart';
import '../../app/theme/pulse_theme.dart';
import '../../core/app_config.dart';
import '../../core/clock.dart';
import '../../data/instruments/models/instrument.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/feed/feed_connection_bloc.dart';
import '../blocs/feed/feed_event.dart';
import '../blocs/feed/feed_state.dart';
import '../blocs/price/price_bloc.dart';
import '../blocs/watchlist/watchlist_bloc.dart';
import '../blocs/watchlist/watchlist_event.dart';
import '../blocs/watchlist/watchlist_state.dart';
import '../widgets/app_lifecycle_bridge.dart';
import '../widgets/connection_banner.dart';
import '../widgets/feed_diagnostics.dart';
import '../widgets/price_row.dart';
import 'instrument_detail_screen.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<WatchlistBloc>(
          create: (_) => getIt<WatchlistBloc>()..add(const WatchlistEvent.requested()),
        ),
        BlocProvider<FeedConnectionBloc>(
          create: (_) => getIt<FeedConnectionBloc>()..add(const FeedEvent.started()),
        ),
        // App-scoped singleton: the connection bloc writes into it through the
        // TickSink port, and it outlives this screen.
        BlocProvider<PriceBloc>.value(value: getIt<PriceBloc>()),
      ],
      // Below the providers, so it can reach both blocs.
      child: const AppLifecycleBridge(child: WatchlistView()),
    );
  }
}

class WatchlistView extends StatelessWidget {
  const WatchlistView({super.key});

  @override
  Widget build(BuildContext context) {
    final AppConfig config = getIt<AppConfig>();

    return MultiBlocListener(
      listeners: <BlocListener<FeedConnectionBloc, FeedState>>[
        BlocListener<FeedConnectionBloc, FeedState>(
          // The feed is the only thing that can discover our credentials are
          // dead, and the only path back to a login screen.
          listenWhen: (FeedState previous, FeedState current) =>
              current.phase == ConnectionPhase.authFailed &&
              previous.phase != ConnectionPhase.authFailed,
          listener: (BuildContext context, FeedState state) {
            context.read<AuthBloc>().add(const AuthEvent.sessionRejected());
          },
        ),
        BlocListener<FeedConnectionBloc, FeedState>(
          // The instrument list is fetched once, so a server that was down at
          // startup leaves the screen stuck on an error while ticks pour into
          // a store with no rows to show them. The feed reaching `live` is
          // proof the server is answering again, so retry off the back of it
          // rather than making the user find the button.
          listenWhen: (FeedState previous, FeedState current) =>
              current.phase == ConnectionPhase.live &&
              previous.phase != ConnectionPhase.live,
          listener: (BuildContext context, FeedState state) {
            if (context.read<WatchlistBloc>().state is WatchlistFailed) {
              context.read<WatchlistBloc>().add(const WatchlistEvent.retried());
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pulse'),
          backgroundColor: PulseColors.surfaceRaised,
          actions: <Widget>[
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout, size: 20),
              onPressed: () {
                context.read<FeedConnectionBloc>().add(const FeedEvent.stopped());
                context.read<AuthBloc>().add(const AuthEvent.logOutRequested());
              },
            ),
          ],
        ),
        body: Column(
          children: <Widget>[
            ConnectionBanner(clock: getIt<Clock>()),
            const FeedDiagnostics(),
            const _ColumnHeaders(),
            Expanded(
              child: BlocBuilder<WatchlistBloc, WatchlistState>(
                builder: (BuildContext context, WatchlistState state) {
                  return switch (state) {
                    WatchlistInitial() ||
                    WatchlistLoading() =>
                      const Center(child: CircularProgressIndicator()),
                    WatchlistFailed(:final String message) =>
                      _LoadFailed(message: message),
                    WatchlistLoaded(:final List<Instrument> instruments) =>
                      _InstrumentList(
                        instruments: instruments,
                        config: config,
                      ),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The list itself.
///
/// Built once per instrument-list change - which is once per session. Price
/// updates never reach this widget: each row subscribes to its own notifier.
class _InstrumentList extends StatelessWidget {
  const _InstrumentList({
    required this.instruments,
    required this.config,
  });

  final List<Instrument> instruments;
  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    final Widget list = ListView.builder(
      itemCount: instruments.length,
      itemExtent: 56,
      itemBuilder: (BuildContext context, int index) {
        final Instrument instrument = instruments[index];
        return PriceRow(
          key: ValueKey<String>(instrument.symbol),
          instrument: instrument,
          config: config,
          onTap: () => _openDetail(context, instrument),
        );
      },
    );

    // Dim the whole list whenever the prices cannot be trusted. `list` is
    // hoisted so the selector rebuild swaps only the opacity - the identical
    // child widget short-circuits reconciliation instead of rebuilding 40
    // rows.
    return BlocSelector<FeedConnectionBloc, FeedState, bool>(
      selector: (FeedState state) => state.isStalePresentation,
      builder: (BuildContext context, bool stale) {
        return AnimatedOpacity(
          opacity: stale ? 0.45 : 1,
          duration: const Duration(milliseconds: 200),
          child: list,
        );
      },
    );
  }
}

/// The detail route is pushed on the root navigator, which sits above the
/// providers in [WatchlistScreen], so the feed bloc is handed down explicitly
/// rather than looked up from a context that cannot see it.
void _openDetail(BuildContext context, Instrument instrument) {
  final FeedConnectionBloc feed = context.read<FeedConnectionBloc>();
  final PriceBloc prices = context.read<PriceBloc>();

  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<FeedConnectionBloc>.value(value: feed),
          BlocProvider<PriceBloc>.value(value: prices),
        ],
        child: InstrumentDetailScreen(
          instrument: instrument,
          config: getIt<AppConfig>(),
          clock: getIt<Clock>(),
        ),
      ),
    ),
  );
}

class _ColumnHeaders extends StatelessWidget {
  const _ColumnHeaders();

  @override
  Widget build(BuildContext context) {
    const TextStyle style = TextStyle(
      fontSize: 10.5,
      color: PulseColors.textSecondary,
      letterSpacing: 0.6,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 24, 8),
      child: const Row(
        children: <Widget>[
          Expanded(flex: 5, child: Text('INSTRUMENT', style: style)),
          Expanded(
            flex: 3,
            child: Text('BID', textAlign: TextAlign.right, style: style),
          ),
          Expanded(
            flex: 3,
            child: Text('ASK', textAlign: TextAlign.right, style: style),
          ),
        ],
      ),
    );
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Could not load instruments.'),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PulseColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  context.read<WatchlistBloc>().add(const WatchlistEvent.retried()),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
