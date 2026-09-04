import 'package:finonex/core/app_config.dart';
import 'package:finonex/data/feed/quote_book.dart';
import 'package:finonex/data/feed/tick.dart';
import 'package:finonex/domain/models/price_cell.dart';
import 'package:flutter_test/flutter_test.dart';

/// The correctness core, tested without any state-management machinery around
/// it: which ticks are real, which are stale, and what survives a window.
void main() {
  const AppConfig config = AppConfig();

  late QuoteBook book;

  setUp(() => book = QuoteBook(config));

  Tick tick({
    String symbol = 'EURUSD',
    double bid = 1.0,
    double ask = 1.1,
    required int ts,
    int? id,
  }) =>
      Tick(symbol: symbol, bid: bid, ask: ask, ts: ts, eventId: id);

  group('duplicate suppression', () {
    test('an event id we have already seen is rejected', () {
      expect(book.add(tick(ts: 1000, id: 1)), isTrue);
      expect(book.add(tick(ts: 2000, id: 1)), isFalse);

      expect(book.stats.duplicates, 1);
      expect(book.stats.accepted, 1);
    });

    test('the window evicts old ids rather than growing forever', () {
      final QuoteBook small = QuoteBook(const AppConfig(dedupWindow: 4));

      for (int id = 1; id <= 5; id++) {
        small.add(tick(symbol: 'S$id', ts: 1000, id: id));
      }
      // id 1 has been evicted, so it is no longer recognised as a duplicate.
      expect(small.add(tick(symbol: 'OLD', ts: 1000, id: 1)), isTrue);
      expect(small.stats.duplicates, 0);
      expect(small.stats.accepted, 6);
    });
  });

  group('ordering', () {
    test('a stale tick never displaces a newer one', () {
      book.add(tick(ts: 5000, id: 1, bid: 1.5));
      book.drainPending();

      // The server's out-of-order event: 3s older, but a brand new id, so id
      // dedup cannot catch it.
      expect(book.add(tick(ts: 2000, id: 2, bid: 9.9)), isFalse);
      expect(book.stats.outOfOrder, 1);
      expect(book.hasPending, isFalse);
    });

    test('an identical timestamp is broken by event id, not discarded', () {
      // The server's burst is synchronous: ~220 ticks land inside the same
      // millisecond, so dozens of ticks per symbol share a ts. Dropping them
      // would pin the symbol to the burst's opening price.
      book.add(tick(ts: 5000, id: 1, bid: 1.5));
      book.drainPending();

      expect(book.add(tick(ts: 5000, id: 2, bid: 7.7)), isTrue);
      expect(book.drainPending().single.bid, 7.7);
      expect(book.stats.outOfOrder, 0);
    });

    test('an identical timestamp with a lower id is a replay', () {
      book.add(tick(ts: 5000, id: 9, bid: 1.5));
      book.drainPending();

      expect(book.add(tick(ts: 5000, id: 4, bid: 7.7)), isFalse);
      expect(book.stats.outOfOrder, 1);
    });

    test('a whole burst inside one millisecond lands on its final price', () {
      for (int i = 1; i <= 55; i++) {
        book.add(tick(ts: 5000, id: i, bid: i.toDouble()));
      }

      expect(book.drainPending().single.bid, 55.0);
      expect(book.stats.outOfOrder, 0);
    });

    test('ordering is tracked per symbol', () {
      book.add(tick(symbol: 'EURUSD', ts: 9000, id: 1));
      expect(book.add(tick(symbol: 'GBPUSD', ts: 1000, id: 2)), isTrue,
          reason: "GBPUSD's clock is its own");
      expect(book.stats.outOfOrder, 0);
    });
  });

  group('conflation', () {
    test('a burst drains to one tick per symbol', () {
      const List<String> hot = <String>['EURUSD', 'GBPUSD', 'XAUUSD'];
      for (int i = 0; i < 220; i++) {
        book.add(tick(
          symbol: hot[i % hot.length],
          ts: 1000 + i,
          id: i + 1,
          bid: 1.0 + i / 1000,
        ));
      }

      final List<Tick> batch = book.drainPending();

      expect(batch.length, 3, reason: '220 ticks, 3 symbols, 3 updates');
      expect(book.stats.accepted, 220);
    });

    test('the surviving tick is the newest in the window', () {
      book.add(tick(ts: 1000, id: 1, bid: 1.0));
      book.add(tick(ts: 1001, id: 2, bid: 2.0));
      book.add(tick(ts: 1002, id: 3, bid: 3.0));

      expect(book.drainPending().single.bid, 3.0);
    });

    test('draining twice yields nothing the second time', () {
      book.add(tick(ts: 1000, id: 1));

      expect(book.drainPending(), hasLength(1));
      expect(book.drainPending(), isEmpty);
    });
  });

  group('session history', () {
    test('tracks extremes across the whole session, not just the window', () {
      final QuoteBook shallow = QuoteBook(const AppConfig(sparklineDepth: 3));

      const List<double> bids = <double>[5, 9, 1, 6, 7];
      for (int i = 0; i < bids.length; i++) {
        shallow.add(tick(ts: 1000 + i, id: i + 1, bid: bids[i]));
        shallow.drainPending();
      }

      final SymbolHistory history = shallow.historyFor('EURUSD');
      expect(history.high, 9, reason: 'the peak scrolled out of the tail');
      expect(history.low, 1);
      expect(history.recent, <double>[1, 6, 7], reason: 'oldest to newest');
    });

    test('samples the conflated series, not every raw tick', () {
      // Three ticks in one window produce one history sample - the same value
      // the screen showed. Documented tradeoff, asserted so it stays deliberate.
      book.add(tick(ts: 1000, id: 1, bid: 1.0));
      book.add(tick(ts: 1001, id: 2, bid: 2.0));
      book.add(tick(ts: 1002, id: 3, bid: 3.0));
      book.drainPending();

      expect(book.historyFor('EURUSD').recent, <double>[3.0]);
    });

    test('an unknown symbol has an empty history rather than throwing', () {
      expect(book.historyFor('NOPE').hasData, isFalse);
    });
  });

  test('malformed events are counted', () {
    book
      ..noteMalformed()
      ..noteMalformed();

    expect(book.stats.malformed, 2);
  });
}
