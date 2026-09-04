import 'package:finonex/core/app_config.dart';
import 'package:finonex/data/feed/price_store.dart';
import 'package:finonex/data/feed/tick.dart';
import 'package:finonex/data/instruments/models/instrument.dart';
import 'package:finonex/presentation/widgets/price_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

/// The performance requirement, asserted rather than asserted-to.
///
/// The brief says a full-list rebuild on every tick will not pass. This test
/// pins the structural property that prevents it: ticks reach the leaf that
/// listens to a symbol's notifier and stop there.
void main() {
  const AppConfig config = AppConfig();

  late MutableClock clock;
  late ManualConflationScheduler scheduler;
  late PriceStore store;

  final List<Instrument> instruments = <Instrument>[
    for (int i = 0; i < 40; i++)
      Instrument(symbol: 'SYM$i', name: 'Instrument $i', decimals: 2),
  ];

  setUp(() {
    clock = MutableClock(DateTime.utc(2026, 1, 1, 12));
    scheduler = ManualConflationScheduler();
    store = PriceStore(config, clock, scheduler);
  });

  tearDown(() => store.dispose());

  /// Counts how many times anything above the price leaf is rebuilt.
  Widget buildList({required void Function() onRowBuild}) {
    return MaterialApp(
      home: Scaffold(
        body: ListView.builder(
          itemCount: instruments.length,
          itemExtent: 56,
          itemBuilder: (BuildContext context, int index) {
            onRowBuild();
            final Instrument instrument = instruments[index];
            return PriceRow(
              key: ValueKey<String>(instrument.symbol),
              instrument: instrument,
              listenable: store.listenableFor(instrument.symbol),
              config: config,
            );
          },
        ),
      ),
    );
  }

  testWidgets('a burst of ticks never rebuilds a row above the price leaf',
      (WidgetTester tester) async {
    int rowBuilds = 0;
    await tester.pumpWidget(buildList(onRowBuild: () => rowBuilds++));
    await tester.pump();

    final int buildsAfterFirstFrame = rowBuilds;
    expect(buildsAfterFirstFrame, greaterThan(0));

    // The server's burst: 220 ticks across a few hot symbols in one window.
    for (int i = 0; i < 220; i++) {
      store.add(Tick(
        symbol: 'SYM${i % 4}',
        bid: 100 + i.toDouble(),
        ask: 101 + i.toDouble(),
        ts: 1000 + i,
        eventId: i + 1,
      ));
    }
    scheduler.flush();
    await tester.pump();
    await tester.pump(config.flashDuration);

    expect(
      rowBuilds,
      buildsAfterFirstFrame,
      reason: 'ticks must not rebuild rows, let alone the list',
    );
  });

  testWidgets('only the ticked symbol changes on screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildList(onRowBuild: () {}));
    await tester.pump();

    // Everything starts blank.
    expect(find.text('-'), findsWidgets);

    store.add(const Tick(
      symbol: 'SYM0',
      bid: 1.23,
      ask: 1.25,
      ts: 1000,
      eventId: 1,
    ));
    scheduler.flush();
    await tester.pump();

    expect(find.text('1.23'), findsOneWidget);
    expect(find.text('1.25'), findsOneWidget);

    // A second symbol's row is untouched and still shows placeholders.
    final Finder sym1 = find.byKey(const ValueKey<String>('SYM1'));
    expect(
      find.descendant(of: sym1, matching: find.text('-')),
      findsNWidgets(2),
    );
  });

  testWidgets('a conflated burst shows only the final price',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildList(onRowBuild: () {}));
    await tester.pump();

    for (int i = 0; i < 50; i++) {
      store.add(Tick(
        symbol: 'SYM0',
        bid: 10 + i.toDouble(),
        ask: 11 + i.toDouble(),
        ts: 1000 + i,
        eventId: i + 1,
      ));
    }
    scheduler.flush();
    await tester.pump();

    expect(find.text('59.00'), findsOneWidget, reason: 'last bid wins');
    expect(find.text('10.00'), findsNothing, reason: 'intermediates never painted');
  });

  testWidgets('an unchanged re-delivery does not restart the flash',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildList(onRowBuild: () {}));

    store.add(const Tick(symbol: 'SYM0', bid: 1.0, ask: 1.1, ts: 1000, eventId: 1));
    scheduler.flush();
    await tester.pump();

    store.add(const Tick(symbol: 'SYM0', bid: 2.0, ask: 2.1, ts: 1001, eventId: 2));
    scheduler.flush();
    await tester.pump();

    final _FlashProbe first = _probe(tester);
    expect(first.isFlashing, isTrue);

    await tester.pump(config.flashDuration);
    expect(_probe(tester).isFlashing, isFalse);

    // Same price again under a fresh id and a newer timestamp: the store keeps
    // the revision put, so no second flash.
    store.add(const Tick(symbol: 'SYM0', bid: 2.0, ask: 2.1, ts: 1002, eventId: 3));
    scheduler.flush();
    await tester.pump();

    expect(_probe(tester).isFlashing, isFalse);
  });
}

class _FlashProbe {
  const _FlashProbe(this.isFlashing);

  final bool isFlashing;
}

/// Reads the flash wash straight off the rendered decoration.
_FlashProbe _probe(WidgetTester tester) {
  final Finder row = find.byKey(const ValueKey<String>('SYM0'));
  final Finder decorated = find.descendant(
    of: row,
    matching: find.byType(DecoratedBox),
  );

  for (final Element element in decorated.evaluate()) {
    final DecoratedBox box = element.widget as DecoratedBox;
    final Color? color = (box.decoration as BoxDecoration).color;
    if (color != null && color.a > 0.01) return const _FlashProbe(true);
  }
  return const _FlashProbe(false);
}
