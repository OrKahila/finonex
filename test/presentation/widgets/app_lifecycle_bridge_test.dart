import 'package:bloc_test/bloc_test.dart';
import 'package:finonex/presentation/blocs/feed/feed_connection_bloc.dart';
import 'package:finonex/presentation/blocs/feed/feed_event.dart';
import 'package:finonex/presentation/blocs/feed/feed_state.dart';
import 'package:finonex/presentation/blocs/price/price_bloc.dart';
import 'package:finonex/presentation/blocs/price/price_event.dart';
import 'package:finonex/presentation/blocs/price/price_state.dart';
import 'package:finonex/presentation/widgets/app_lifecycle_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFeedConnectionBloc extends MockBloc<FeedEvent, FeedState>
    implements FeedConnectionBloc {}

class MockPriceBloc extends MockBloc<PriceEvent, PriceState>
    implements PriceBloc {}

void main() {
  late MockFeedConnectionBloc feed;
  late MockPriceBloc prices;

  setUpAll(() {
    registerFallbackValue(const FeedEvent.appBackgrounded());
    registerFallbackValue(const PriceEvent.stalenessChecked());
  });

  setUp(() {
    feed = MockFeedConnectionBloc();
    prices = MockPriceBloc();
    whenListen(feed, const Stream<FeedState>.empty(),
        initialState: const FeedState());
    whenListen(prices, const Stream<PriceState>.empty(),
        initialState: const PriceState());
  });

  Future<void> pumpBridge(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: <BlocProvider<dynamic>>[
            BlocProvider<FeedConnectionBloc>.value(value: feed),
            BlocProvider<PriceBloc>.value(value: prices),
          ],
          child: const AppLifecycleBridge(child: SizedBox()),
        ),
      ),
    );
  }

  Future<void> send(WidgetTester tester, List<AppLifecycleState> states) async {
    for (final AppLifecycleState state in states) {
      tester.binding.handleAppLifecycleStateChanged(state);
      await tester.pump();
    }
  }

  testWidgets('going to the background drops the feed',
      (WidgetTester tester) async {
    await pumpBridge(tester);

    // The full iOS sequence on the way out.
    await send(tester, <AppLifecycleState>[
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]);

    verify(() => feed.add(const FeedEvent.appBackgrounded())).called(1);
  });

  testWidgets('coming back reconnects and re-checks staleness at once',
      (WidgetTester tester) async {
    await pumpBridge(tester);

    await send(tester, <AppLifecycleState>[
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]);

    verify(() => feed.add(const FeedEvent.appForegrounded())).called(1);
    verify(() => prices.add(const PriceEvent.stalenessChecked())).called(1);
  });

  testWidgets('a transient inactive does not drop the feed',
      (WidgetTester tester) async {
    await pumpBridge(tester);

    // Control Centre, the app switcher, an incoming call, a permission
    // dialog: the app goes inactive and comes straight back. Dropping the
    // stream here would mean a reconnect every time someone glances at their
    // notifications.
    await send(tester, <AppLifecycleState>[
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]);

    verifyNever(() => feed.add(const FeedEvent.appBackgrounded()));
  });
}
