import 'package:finonex/core/app_config.dart';
import 'package:finonex/data/feed/price_cell.dart';
import 'package:finonex/data/feed/price_store.dart';
import 'package:finonex/data/feed/tick.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  const AppConfig config = AppConfig();

  late MutableClock clock;
  late ManualConflationScheduler scheduler;
  late PriceStore store;

  setUp(() {
    clock = MutableClock(DateTime.utc(2026, 1, 1, 12));
    scheduler = ManualConflationScheduler();
    store = PriceStore(config, clock, scheduler);
  });

  tearDown(() => store.dispose());

  Tick tick({
    String symbol = 'EURUSD',
    double bid = 1.0,
    double ask = 1.1,
    required int ts,
    int? id,
  }) =>
      Tick(symbol: symbol, bid: bid, ask: ask, ts: ts, eventId: id);

  PriceCell cellOf(String symbol) => store.listenableFor(symbol).value;

  group('duplicate suppression', () {
    test('an event id we have already seen is dropped', () {
      store.add(tick(ts: 1000, id: 1, bid: 1.0));
      store.add(tick(ts: 2000, id: 1, bid: 2.0));
      scheduler.flush();

      expect(cellOf('EURUSD').bid, 1.0);
      expect(store.stats.value.duplicates, 1);
      expect(store.stats.value.accepted, 1);
    });

    test('a re-delivered identical price cannot produce a second flash', () {
      store.add(tick(ts: 1000, id: 1, bid: 1.0));
      scheduler.flush();
      // Passes both filters - new id, later ts - but the price did not move,
      // so the revision the flash keys off must not budge.
      store.add(tick(ts: 1001, id: 2, bid: 1.0));
      scheduler.flush();

      expect(cellOf('EURUSD').revision, 1);
    });

    test('the window evicts old ids rather than growing forever', () {
      const AppConfig smallWindow = AppConfig(dedupWindow: 4);
      final PriceStore small = PriceStore(smallWindow, clock, scheduler);

      for (int id = 1; id <= 5; id++) {
        small.add(tick(symbol: 'S$id', ts: 1000, id: id));
      }
      // id 1 has now been evicted, so it is no longer recognised as a dupe.
      small.add(tick(symbol: 'OLD', ts: 1000, id: 1));
      scheduler.flush();

      expect(small.stats.value.duplicates, 0);
      expect(small.stats.value.accepted, 6);
      small.dispose();
    });
  });

  group('ordering', () {
    test('a stale tick never overwrites a newer price', () {
      store.add(tick(ts: 5000, id: 1, bid: 1.5));
      scheduler.flush();

      // The server's out-of-order event: 3s older, but a brand new id, so id
      // dedup cannot catch it.
      store.add(tick(ts: 2000, id: 2, bid: 9.9));
      scheduler.flush();

      expect(cellOf('EURUSD').bid, 1.5);
      expect(cellOf('EURUSD').ts, 5000);
      expect(store.stats.value.outOfOrder, 1);
    });

    test('an identical timestamp is broken by event id, not discarded', () {
      // The server's burst is synchronous: ~220 ticks land inside the same
      // millisecond, so dozens of ticks per symbol share a ts. Dropping them
      // would pin the row to the burst's opening price.
      store.add(tick(ts: 5000, id: 1, bid: 1.5));
      scheduler.flush();
      store.add(tick(ts: 5000, id: 2, bid: 7.7));
      scheduler.flush();

      expect(cellOf('EURUSD').bid, 7.7);
      expect(store.stats.value.outOfOrder, 0);
    });

    test('an identical timestamp with a lower id is stale', () {
      store.add(tick(ts: 5000, id: 9, bid: 1.5));
      scheduler.flush();
      store.add(tick(ts: 5000, id: 4, bid: 7.7));
      scheduler.flush();

      expect(cellOf('EURUSD').bid, 1.5);
      expect(store.stats.value.outOfOrder, 1);
    });

    test('a whole burst inside one millisecond lands on its final price', () {
      for (int i = 1; i <= 55; i++) {
        store.add(tick(ts: 5000, id: i, bid: i.toDouble()));
      }
      scheduler.flush();

      expect(cellOf('EURUSD').bid, 55.0);
      expect(store.stats.value.outOfOrder, 0);
    });

    test('a newer timestamp is accepted', () {
      store.add(tick(ts: 5000, id: 1, bid: 1.5));
      store.add(tick(ts: 5001, id: 2, bid: 1.6));
      scheduler.flush();

      expect(cellOf('EURUSD').bid, 1.6);
    });

    test('ordering is tracked per symbol', () {
      store.add(tick(symbol: 'EURUSD', ts: 9000, id: 1, bid: 1.0));
      store.add(tick(symbol: 'GBPUSD', ts: 1000, id: 2, bid: 2.0));
      scheduler.flush();

      // GBPUSD's older timestamp is irrelevant to EURUSD's clock.
      expect(cellOf('GBPUSD').bid, 2.0);
      expect(store.stats.value.outOfOrder, 0);
    });
  });

  group('conflation', () {
    test('a burst collapses to one write per symbol', () {
      final Map<String, int> notifications = <String, int>{};
      for (final String symbol in <String>['EURUSD', 'GBPUSD', 'XAUUSD']) {
        store.listenableFor(symbol).addListener(
              () => notifications[symbol] = (notifications[symbol] ?? 0) + 1,
            );
      }

      // The server's burst shape: 220 ticks across a handful of hot symbols
      // inside one window.
      const List<String> hot = <String>['EURUSD', 'GBPUSD', 'XAUUSD'];
      for (int i = 0; i < 220; i++) {
        store.add(tick(
          symbol: hot[i % hot.length],
          ts: 1000 + i,
          id: i + 1,
          bid: 1.0 + i / 1000,
        ));
      }
      scheduler.flush();

      expect(notifications, <String, int>{'EURUSD': 1, 'GBPUSD': 1, 'XAUUSD': 1},
          reason: '220 ticks must cost 3 widget rebuilds, not 220');
      expect(store.stats.value.accepted, 220);
    });

    test('the surviving value is the newest in the window', () {
      store.add(tick(ts: 1000, id: 1, bid: 1.0));
      store.add(tick(ts: 1001, id: 2, bid: 2.0));
      store.add(tick(ts: 1002, id: 3, bid: 3.0));
      scheduler.flush();

      expect(cellOf('EURUSD').bid, 3.0);
      expect(cellOf('EURUSD').revision, 1, reason: 'one visible change');
    });

    test('flash direction is the net move across the window', () {
      store.add(tick(ts: 1000, id: 1, bid: 5.0));
      scheduler.flush();

      // Price thrashes up and down but ends lower than where it started.
      store.add(tick(ts: 1001, id: 2, bid: 9.0));
      store.add(tick(ts: 1002, id: 3, bid: 1.0));
      scheduler.flush();

      expect(cellOf('EURUSD').direction, PriceDirection.down);
    });

    test('the first tick for a symbol does not flash', () {
      store.add(tick(ts: 1000, id: 1, bid: 5.0));
      scheduler.flush();

      expect(cellOf('EURUSD').direction, PriceDirection.none);
      expect(cellOf('EURUSD').revision, 1);
    });

    test('an unchanged price does not bump the revision', () {
      store.add(tick(ts: 1000, id: 1, bid: 5.0, ask: 5.1));
      scheduler.flush();
      store.add(tick(ts: 1001, id: 2, bid: 5.0, ask: 5.1));
      scheduler.flush();

      expect(cellOf('EURUSD').revision, 1, reason: 'no move, no flash');
      expect(cellOf('EURUSD').direction, PriceDirection.none);
      expect(cellOf('EURUSD').ts, 1001, reason: 'but it is still fresh data');
    });

    test('repeated ticks schedule only one pending flush', () {
      for (int i = 0; i < 50; i++) {
        store.add(tick(ts: 1000 + i, id: i + 1));
      }

      expect(scheduler.scheduleCalls, 50);
      expect(scheduler.flush(), isTrue);
      expect(scheduler.flush(), isFalse, reason: 'flushes must collapse into one');
    });
  });

  group('diagnostics', () {
    test('malformed events are counted', () {
      store.noteMalformed();
      store.noteMalformed();
      scheduler.flush();

      expect(store.stats.value.malformed, 2);
    });

    test('stats update once per flush, not once per tick', () {
      int statsWrites = 0;
      store.stats.addListener(() => statsWrites++);

      for (int i = 0; i < 100; i++) {
        store.add(tick(ts: 1000 + i, id: i + 1));
      }
      scheduler.flush();

      expect(statsWrites, 1);
    });
  });

  group('staleness', () {
    test('a symbol that stops ticking is flagged, and unflagged when it resumes',
        () {
      // The sweep runs on a real periodic timer; drive its logic through the
      // public surface by advancing the clock and letting the timer fire.
      fakeTimerSweep(store, clock, config);
    });
  });
}

/// The staleness sweep is a 1s periodic timer inside the store. Rather than
/// reach into it, assert the observable contract: a cell goes stale after the
/// configured window and comes back when a fresh tick lands.
void fakeTimerSweep(PriceStore store, MutableClock clock, AppConfig config) {
  store.add(const Tick(symbol: 'EURUSD', bid: 1.0, ask: 1.1, ts: 1000, eventId: 1));
  store.flushNow();

  final ValueListenable<PriceCell> cell = store.listenableFor('EURUSD');
  expect(cell.value.isStale, isFalse);

  clock.advance(config.staleBadgeAfter + const Duration(seconds: 1));
  store.debugSweepStaleness();
  expect(cell.value.isStale, isTrue);

  store.add(const Tick(symbol: 'EURUSD', bid: 1.2, ask: 1.3, ts: 2000, eventId: 2));
  store.flushNow();
  expect(cell.value.isStale, isFalse);
}
