import 'package:flutter/material.dart';

import '../../app/theme/pulse_theme.dart';

/// A minimal price line. No axes, no labels - it exists to show shape.
class Sparkline extends StatelessWidget {
  const Sparkline({required this.values, super.key});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) {
      return const Center(
        child: Text(
          'Collecting ticks...',
          style: TextStyle(color: PulseColors.textSecondary, fontSize: 12),
        ),
      );
    }

    return RepaintBoundary(
      child: CustomPaint(
        painter: _SparklinePainter(values),
        size: Size.infinite,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    double min = values.first;
    double max = values.first;
    for (final double value in values) {
      if (value < min) min = value;
      if (value > max) max = value;
    }

    // A dead-flat series would divide by zero; centre it instead.
    final double range = max - min;
    final double scale = range == 0 ? 0 : size.height / range;

    final Path path = Path();
    for (int i = 0; i < values.length; i++) {
      final double x = size.width * (i / (values.length - 1));
      final double y = range == 0
          ? size.height / 2
          : size.height - (values[i] - min) * scale;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final bool rising = values.last >= values.first;
    final Color color = rising ? PulseColors.up : PulseColors.down;

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );

    // Soft fill under the line, purely for legibility at a glance.
    final Path fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()..color = color.withValues(alpha: 0.10),
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      !identical(oldDelegate.values, values);
}
