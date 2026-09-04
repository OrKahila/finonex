import 'package:bloc_test/bloc_test.dart';
import 'package:finonex/presentation/blocs/feed/feed_connection_bloc.dart';
import 'package:finonex/presentation/blocs/feed/feed_event.dart';
import 'package:finonex/presentation/blocs/feed/feed_state.dart';
import 'package:finonex/presentation/widgets/connection_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

class MockFeedConnectionBloc extends MockBloc<FeedEvent, FeedState>
    implements FeedConnectionBloc {}

/// The requirement is blunt: "the user must never look at frozen prices
/// believing they're live". These assert the banner says so in every phase.
void main() {
  final DateTime now = DateTime.utc(2026, 1, 1, 12);
  late MockFeedConnectionBloc bloc;

  setUp(() => bloc = MockFeedConnectionBloc());

  Future<void> pumpWith(WidgetTester tester, FeedState state) async {
    whenListen(bloc, const Stream<FeedState>.empty(), initialState: state);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<FeedConnectionBloc>.value(
            value: bloc,
            child: ConnectionBanner(clock: MutableClock(now)),
          ),
        ),
      ),
    );
  }

  testWidgets('live says live', (WidgetTester tester) async {
    await pumpWith(tester, const FeedState(phase: ConnectionPhase.live));
    expect(find.text('Live'), findsOneWidget);
  });

  testWidgets('connecting is distinguishable from live',
      (WidgetTester tester) async {
    await pumpWith(tester, const FeedState(phase: ConnectionPhase.connecting));
    expect(find.textContaining('Connecting'), findsOneWidget);
  });

  testWidgets('a stall names the silence and disclaims the prices',
      (WidgetTester tester) async {
    await pumpWith(
      tester,
      FeedState(
        phase: ConnectionPhase.degraded,
        silentSince: now.subtract(const Duration(seconds: 9)),
      ),
    );

    expect(find.textContaining('Stalled'), findsOneWidget);
    expect(find.textContaining('9s'), findsOneWidget);
    expect(find.textContaining('not current'), findsOneWidget);
  });

  testWidgets('reconnecting shows the countdown and the attempt number',
      (WidgetTester tester) async {
    await pumpWith(
      tester,
      FeedState(
        phase: ConnectionPhase.reconnecting,
        attempt: 3,
        nextAttemptAt: now.add(const Duration(seconds: 4)),
      ),
    );

    expect(find.textContaining('Reconnecting in 4s'), findsOneWidget);
    expect(find.textContaining('attempt 3'), findsOneWidget);
  });

  testWidgets('offline explains why nothing is being retried',
      (WidgetTester tester) async {
    await pumpWith(tester, const FeedState(phase: ConnectionPhase.offline));
    expect(find.textContaining('offline'), findsOneWidget);
  });

  testWidgets('auth failure surfaces the reason', (WidgetTester tester) async {
    await pumpWith(
      tester,
      const FeedState(
        phase: ConnectionPhase.authFailed,
        message: 'Stored credentials were rejected.',
      ),
    );

    expect(find.text('Stored credentials were rejected.'), findsOneWidget);
  });

  testWidgets('gaps are surfaced rather than implying continuity',
      (WidgetTester tester) async {
    await pumpWith(
      tester,
      const FeedState(phase: ConnectionPhase.live, gapCount: 2),
    );

    expect(find.text('2 gaps'), findsOneWidget);
  });
}
