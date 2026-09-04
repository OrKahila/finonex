import 'package:bloc_test/bloc_test.dart';
import 'package:finonex/app/di/injector.dart';
import 'package:finonex/core/app_config.dart';
import 'package:finonex/core/clock.dart';
import 'package:finonex/presentation/blocs/price/price_bloc.dart';
import 'package:finonex/presentation/blocs/auth/auth_bloc.dart';
import 'package:finonex/presentation/blocs/auth/auth_event.dart';
import 'package:finonex/presentation/blocs/auth/auth_state.dart';
import 'package:finonex/presentation/blocs/feed/feed_connection_bloc.dart';
import 'package:finonex/presentation/blocs/feed/feed_event.dart';
import 'package:finonex/presentation/blocs/feed/feed_state.dart';
import 'package:finonex/presentation/blocs/watchlist/watchlist_bloc.dart';
import 'package:finonex/presentation/blocs/watchlist/watchlist_event.dart';
import 'package:finonex/presentation/blocs/watchlist/watchlist_state.dart';
import 'package:finonex/presentation/screens/watchlist_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:finonex/data/instruments/models/instrument.dart';

import '../support/fakes.dart';

class MockFeedConnectionBloc extends MockBloc<FeedEvent, FeedState>
    implements FeedConnectionBloc {}

class MockWatchlistBloc extends MockBloc<WatchlistEvent, WatchlistState>
    implements WatchlistBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

/// Regression test for a bug found by watching the real app: the feed server
/// was restarted, the feed reconnected and went live on its own, but the
/// instrument list stayed pinned to its error screen. Ticks were flowing into
/// the store with no rows to render them, and only a manual tap could fix it.
void main() {
  const AppConfig config = AppConfig();

  late MockFeedConnectionBloc feed;
  late MockWatchlistBloc watchlist;
  late MockAuthBloc auth;

  setUpAll(() {
    registerFallbackValue(const WatchlistEvent.retried());
    registerFallbackValue(const AuthEvent.logOutRequested());
  });

  setUp(() {
    feed = MockFeedConnectionBloc();
    watchlist = MockWatchlistBloc();
    auth = MockAuthBloc();

    if (!getIt.isRegistered<AppConfig>()) {
      getIt
        ..registerSingleton<AppConfig>(config)
        ..registerSingleton<Clock>(const SystemClock());
    }
  });

  Future<void> pump(
    WidgetTester tester, {
    required Stream<FeedState> feedStates,
    required WatchlistState watchlistState,
  }) async {
    whenListen(feed, feedStates, initialState: const FeedState());
    whenListen(watchlist, const Stream<WatchlistState>.empty(),
        initialState: watchlistState);
    whenListen(auth, const Stream<AuthState>.empty(),
        initialState: const AuthAuthenticated());

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: <BlocProvider<dynamic>>[
            BlocProvider<AuthBloc>.value(value: auth),
            BlocProvider<WatchlistBloc>.value(value: watchlist),
            BlocProvider<FeedConnectionBloc>.value(value: feed),
            BlocProvider<PriceBloc>(
              create: (_) => PriceBloc(
                config,
                MutableClock(DateTime.utc(2026)),
                ManualConflationScheduler(),
                ManualPeriodicTicker(),
              ),
            ),
          ],
          child: const WatchlistView(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('the feed going live retries a failed instrument load',
      (WidgetTester tester) async {
    await pump(
      tester,
      feedStates: Stream<FeedState>.value(
        const FeedState(phase: ConnectionPhase.live),
      ),
      watchlistState: const WatchlistState.failed('Connection refused'),
    );
    await tester.pump();

    verify(() => watchlist.add(const WatchlistEvent.retried())).called(1);
  });

  testWidgets('a healthy list is not reloaded when the feed reconnects',
      (WidgetTester tester) async {
    await pump(
      tester,
      feedStates: Stream<FeedState>.value(
        const FeedState(phase: ConnectionPhase.live),
      ),
      watchlistState: const WatchlistState.loaded(<Instrument>[]),
    );
    await tester.pump();

    verifyNever(() => watchlist.add(any()));
  });

  testWidgets('an auth failure hands the user back to the login screen',
      (WidgetTester tester) async {
    await pump(
      tester,
      feedStates: Stream<FeedState>.value(
        const FeedState(phase: ConnectionPhase.authFailed),
      ),
      watchlistState: const WatchlistState.loaded(<Instrument>[]),
    );
    await tester.pump();

    verify(() => auth.add(const AuthEvent.sessionRejected())).called(1);
  });
}
