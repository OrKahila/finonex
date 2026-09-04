import 'package:flutter/material.dart';

/// Domain colours for market data and connection health.
///
/// Deliberately not folded into [ColorScheme]: "price went up" and "the feed is
/// degraded" are domain states, not Material roles.
abstract final class PulseColors {
  static const Color up = Color(0xFF3DD68C);
  static const Color down = Color(0xFFF2555A);
  static const Color upWash = Color(0x333DD68C);
  static const Color downWash = Color(0x33F2555A);

  static const Color live = Color(0xFF3DD68C);
  static const Color connecting = Color(0xFF8A9099);
  static const Color degraded = Color(0xFFF5C451);
  static const Color reconnecting = Color(0xFFF08C3A);
  static const Color offline = Color(0xFFF2555A);

  static const Color surface = Color(0xFF12151A);
  static const Color surfaceRaised = Color(0xFF1A1F26);
  static const Color divider = Color(0xFF262C35);
  static const Color textPrimary = Color(0xFFE8EBEF);
  static const Color textSecondary = Color(0xFF8A9099);
}

ThemeData buildPulseTheme() {
  final ThemeData base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: PulseColors.surface,
    colorScheme: base.colorScheme.copyWith(
      surface: PulseColors.surface,
      primary: PulseColors.live,
      error: PulseColors.offline,
    ),
    dividerColor: PulseColors.divider,
    textTheme: base.textTheme.apply(
      bodyColor: PulseColors.textPrimary,
      displayColor: PulseColors.textPrimary,
    ),
    // Prices are tabular: fixed-width digits stop rows from jittering as
    // values change width.
    typography: base.typography,
  );
}

/// Monospaced, tabular figures for anything showing a price.
const TextStyle kPriceTextStyle = TextStyle(
  fontFamily: 'monospace',
  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  fontSize: 15,
  height: 1.1,
);
