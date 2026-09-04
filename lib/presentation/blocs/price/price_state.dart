import '../../../domain/models/price_cell.dart';

/// The quote board: the current cell for every symbol that has ticked, plus
/// the feed's own diagnostics.
///
/// **Hand-written rather than freezed, on purpose.** Freezed generates
/// `DeepCollectionEquality` for collection fields, so bloc would deep-compare
/// every quote on every emit just to decide whether to emit at all - O(symbols)
/// of pure waste at frame cadence. Equality here is a revision counter, which
/// is O(1) and exactly as correct: [quotes] is never mutated in place, so a new
/// revision is the only way its contents can differ.
class PriceState {
  const PriceState({
    this.quotes = const <String, PriceCell>{},
    this.stats = const FeedStats(),
    this.revision = 0,
  });

  /// Symbol -> current quote.
  ///
  /// Copy-on-write: a flush builds a new map and replaces only the symbols
  /// that moved. Untouched symbols keep the *same* [PriceCell] instance, which
  /// is what lets `BlocSelector` skip their rows on reference equality.
  final Map<String, PriceCell> quotes;

  final FeedStats stats;

  /// Increments on every emit. See the class comment.
  final int revision;

  PriceCell cellFor(String symbol) => quotes[symbol] ?? PriceCell.empty;

  PriceState next({
    Map<String, PriceCell>? quotes,
    FeedStats? stats,
  }) =>
      PriceState(
        quotes: quotes ?? this.quotes,
        stats: stats ?? this.stats,
        revision: revision + 1,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceState && other.revision == revision;

  @override
  int get hashCode => revision;

  @override
  String toString() =>
      'PriceState(symbols: ${quotes.length}, rev: $revision, $stats)';
}
