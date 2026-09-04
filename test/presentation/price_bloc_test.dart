import 'package:finonex/core/app_config.dart';
import 'package:finonex/data/feed/tick.dart';
import 'package:finonex/domain/models/price_cell.dart';
import 'package:finonex/presentation/blocs/price/price_bloc.dart';
import 'package:finonex/presentation/blocs/price/price_event.dart';
import 'package:finonex/presentation/blocs/price/price_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

/// The data plane as a bloc. The property under test throughout is that
/// ticks never reach `emit` one at a time.
void main() {
  const AppConfig config = AppConfig();

  late MutableClock clock;
  late ManualConflationScheduler scheduler;
  late ManualPeriodicTicker staleTicker;
  late PriceBloc bloc;
  late List<PriceState> states;

  setUp(() {
    clock = MutableClock(DateTime.utc(2026, 1, 1, 12));
    scheduler = ManualConflationScheduler();
    staleTicker = ManualPeriodicTicker();
    bloc = PriceBloc(config, clock, scheduler, staleTicker);
    states = <PriceState>[];
    bloc.stream.listen(states.add);
  });

  tearDown(() => bloc.close());

  Tick tick({
    String symbol = 'EURUSD',
    double bid = 1.0,
    double ask = 1.1,
    required int ts,
    int? id,
  }) =>
      Tick(symbol: symbol, bid: bid, ask: ask, ts: ts, eventId: id);

  /// Feeds ticks the way the sink adapter does, then closes the window.
  Future<void> feed(List<Tick> ticks) async {
    for (final Tick t in ticks) {
      bloc.add(PriceEvent.tickReceived(t));
    }
    await pumpEventQueue();
    scheduler.flush();
    await pumpEventQueue();
  }

  PriceCell cell(String symbol) => bloc.state.cellFor(symbol);

  group('conflation', () {
    test('a 220-tick burst produces exactly one state emission', () async {
      const List<String> hot = <String>['EURUSD', 'GBPUSD', 'XAUUSD'];

      await feed(<Tick>[
        for (int i = 0; i < 220; i++)
          tick(
            symbol: hot[i % hot.length],
            ts: 1000 + i,
            id: i + 1,
            bid: 1.0 + i / 1000,
          ),
      ]);

      expect(states, hasLength(1),
          reason: '220 ticks must not be 220 emissions');
      expect(states.single.quotes.keys, containsAll(hot));
      expect(states.single.stats.accepted, 220);
    });

    test('repeated ticks collapse into a single pending flush', () async {
      for (int i = 0; i < 50; i++) {
        bloc.add(PriceEvent.tickReceived(tick(ts: 1000 + i, id: i + 1)));
      }
      await pumpEventQueue();

      expect(scheduler.scheduleCalls, 50);
      expect(scheduler.flush(), isTrue);
      await pumpEventQueue();
      expect(scheduler.flush(), isFalse, reason: 'flushes must collapse');
      expect(states, hasLength(1));
    });

    test('the published price is the newest in the window', () async {
      await feed(<Tick>[
        tick(ts: 1000, id: 1, bid: 1.0),
        tick(ts: 1001, id: 2, bid: 2.0),
        tick(ts: 1002, id: 3, bid: 3.0),
      ]);

      expect(cell('EURUSD').bid, 3.0);
      expect(cell('EURUSD').revision, 1, reason: 'one visible change');
    });
  });

  group('the BlocSelector contract', () {
    // These two are the guard rail for the whole design: BlocSelector only
    // skips a rebuild when the selected value is unchanged, so an emission
    // must not disturb cells that did not move.
    test('untouched symbols keep the identical cell instance', () async {
      await feed(<Tick>[
        tick(symbol: 'EURUSD', ts: 1000, id: 1),
        tick(symbol: 'GBPUSD', ts: 1000, id: 2),
      ]);

      final PriceCell before = cell('GBPUSD');

      await feed(<Tick>[tick(symbol: 'EURUSD', ts: 2000, id: 3, bid: 5.0)]);

      expect(identical(cell('GBPUSD'), before), isTrue,
          reason: 'GBPUSD did not move, so its row must not rebuild');
      expect(cell('EURUSD').bid, 5.0);
    });

    test('a symbol with no data returns a stable empty cell', () {
      expect(identical(bloc.state.cellFor('NOPE'), PriceCell.empty), isTrue);
    });

    test('a counters-only flush leaves every quote instance untouched',
        () async {
      await feed(<Tick>[tick(ts: 1000, id: 1)]);
      final Map<String, PriceCell> quotes = bloc.state.quotes;

      bloc.add(const PriceEvent.malformedReceived());
      await pumpEventQueue();
      scheduler.flush();
      await pumpEventQueue();

      expect(bloc.state.stats.malformed, 1);
      expect(identical(bloc.state.quotes, quotes), isTrue,
          reason: 'a malformed event must not rebuild any row');
    });
  });

  group('flash semantics', () {
    test('direction is the net move across the window', () async {
      await feed(<Tick>[tick(ts: 1000, id: 1, bid: 5.0)]);

      // Thrashes up and down but ends lower than it started.
      await feed(<Tick>[
        tick(ts: 1001, id: 2, bid: 9.0),
        tick(ts: 1002, id: 3, bid: 1.0),
      ]);

      expect(cell('EURUSD').direction, PriceDirection.down);
    });

    test('the first tick for a symbol does not flash', () async {
      await feed(<Tick>[tick(ts: 1000, id: 1, bid: 5.0)]);

      expect(cell('EURUSD').direction, PriceDirection.none);
      expect(cell('EURUSD').revision, 1);
    });

    test('an ask-only move flashes in the direction the ask went', () async {
      // The bid rounds to the same value while the ask moves up. Comparing
      // bids alone would call this a down-tick and paint the row red.
      await feed(<Tick>[tick(ts: 1000, id: 1, bid: 1.0812, ask: 1.0814)]);
      await feed(<Tick>[tick(ts: 1001, id: 2, bid: 1.0812, ask: 1.0816)]);

      expect(cell('EURUSD').direction, PriceDirection.up);
      expect(cell('EURUSD').revision, 2, reason: 'the price did move');
    });

    test('an ask-only move down flashes down', () async {
      await feed(<Tick>[tick(ts: 1000, id: 1, bid: 1.0812, ask: 1.0816)]);
      await feed(<Tick>[tick(ts: 1001, id: 2, bid: 1.0812, ask: 1.0814)]);

      expect(cell('EURUSD').direction, PriceDirection.down);
    });

    test('a spread change with an unchanged mid has no direction', () async {
      // Both sides moved, the market did not. Painting this red or green
      // would be inventing a signal.
      await feed(<Tick>[tick(ts: 1000, id: 1, bid: 1.0, ask: 1.2)]);
      await feed(<Tick>[tick(ts: 1001, id: 2, bid: 0.9, ask: 1.3)]);

      expect(cell('EURUSD').direction, PriceDirection.none);
    });

    test('an unchanged price does not bump the revision', () async {
      await feed(<Tick>[tick(ts: 1000, id: 1, bid: 5.0, ask: 5.1)]);
      await feed(<Tick>[tick(ts: 1001, id: 2, bid: 5.0, ask: 5.1)]);

      expect(cell('EURUSD').revision, 1, reason: 'no move, no flash');
      expect(cell('EURUSD').direction, PriceDirection.none);
      expect(cell('EURUSD').ts, 1001, reason: 'but it is still fresh data');
    });
  });

  group('staleness', () {
    test('a quiet symbol is badged, and cleared when it resumes', () async {
      await feed(<Tick>[tick(ts: 1000, id: 1)]);
      expect(cell('EURUSD').isStale, isFalse);

      clock.advance(config.staleBadgeAfter + const Duration(seconds: 1));
      staleTicker.fire();
      await pumpEventQueue();
      expect(cell('EURUSD').isStale, isTrue);

      await feed(<Tick>[tick(ts: 2000, id: 2, bid: 2.0)]);
      expect(cell('EURUSD').isStale, isFalse);
    });

    test('a sweep that changes nothing does not emit', () async {
      await feed(<Tick>[tick(ts: 1000, id: 1)]);
      final int before = states.length;

      staleTicker.fire();
      await pumpEventQueue();

      expect(states, hasLength(before),
          reason: 'a quiet sweep must cost nothing');
    });
  });

  test('history is exposed without being carried in state', () async {
    await feed(<Tick>[tick(ts: 1000, id: 1, bid: 1.0)]);
    await feed(<Tick>[tick(ts: 1001, id: 2, bid: 2.0)]);

    expect(bloc.historyFor('EURUSD').recent, <double>[1.0, 2.0]);
  });
}
