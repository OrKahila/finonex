import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Frame-timing recorder for profile-mode measurement on a physical device.
///
/// `addTimingsCallback` hands us the engine's own per-frame build and raster
/// durations - the same numbers DevTools' performance chart draws. The reason
/// to accumulate them here rather than read them off that chart is that a p95
/// needs the whole population: DevTools shows a rolling window of recent
/// frames, which answers "did that burst jank" but not "what does this app do
/// over five thousand frames".
///
/// Inert unless the build is profile mode. Debug numbers would be measuring
/// the framework's instrumentation rather than the app - NOTES.md §10 is
/// explicit that the debug figures are indicative only - and a release build
/// has no reason to carry a reporter.
class FrameReport {
  FrameReport({this.reportEvery = const Duration(seconds: 10)});

  /// How often a summary line is printed. Each one also restates the
  /// cumulative picture, so the last line of a run is the whole run.
  final Duration reportEvery;

  final List<int> _buildUs = <int>[];
  final List<int> _rasterUs = <int>[];

  /// Index into the sample lists where the current window began.
  int _windowStart = 0;
  final Stopwatch _sinceReport = Stopwatch();

  /// One frame at 60Hz. The phone renders at 120Hz when ProMotion is awake, so
  /// this is the lenient budget of the two and a frame over it is unambiguous.
  static const int _budgetUs = 16667;

  void start() {
    if (!kProfileMode) return;
    _sinceReport.start();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  /// Drops everything recorded so far, so a specific stretch - one burst, one
  /// reconnect - can be measured on its own.
  void reset() {
    _buildUs.clear();
    _rasterUs.clear();
    _windowStart = 0;
    _sinceReport.reset();
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final FrameTiming timing in timings) {
      final int build = timing.buildDuration.inMicroseconds;
      final int raster = timing.rasterDuration.inMicroseconds;
      _buildUs.add(build);
      _rasterUs.add(raster);
      if (build >= _budgetUs || raster >= _budgetUs) {
        // Printed the moment it happens, with a wall clock, so a spike can be
        // lined up against things observed from outside the app - connection
        // churn on the server, GC events on the VM service. The percentile
        // lines are 10s buckets, which is far too coarse to attribute a single
        // frame. Note this timestamp is the callback, a frame or two after the
        // frame itself.
        debugPrint(
          '[frames] SPIKE ${DateTime.now().toIso8601String()} '
          'build ${(build / 1000.0).toStringAsFixed(1)} '
          'raster ${(raster / 1000.0).toStringAsFixed(1)} ms',
        );
      }
    }
    if (_sinceReport.elapsed >= reportEvery) {
      report();
      _windowStart = _buildUs.length;
      _sinceReport.reset();
    }
  }

  void report() {
    if (_buildUs.isEmpty) return;
    final double windowSeconds = _sinceReport.elapsedMilliseconds / 1000.0;
    debugPrint(
      '[frames] window ${_buildUs.length - _windowStart} frames in '
      '${windowSeconds.toStringAsFixed(1)}s'
      '${_summarise(_buildUs, _rasterUs, _windowStart)}',
    );
    debugPrint(
      '[frames] cumulative ${_buildUs.length} frames'
      '${_summarise(_buildUs, _rasterUs, 0)}',
    );
  }

  String _summarise(List<int> build, List<int> raster, int from) {
    final List<int> b = build.sublist(from)..sort();
    final List<int> r = raster.sublist(from)..sort();
    final int overBudget = b.length - _lowerBound(b, _budgetUs);
    return ' | build ${_percentiles(b)}'
        ' | raster ${_percentiles(r)}'
        ' | build over 16.7ms: $overBudget';
  }

  String _percentiles(List<int> sorted) {
    String at(double quantile) {
      final int index = ((sorted.length - 1) * quantile).round();
      return (sorted[index] / 1000.0).toStringAsFixed(1);
    }

    return 'p50 ${at(0.50)} p90 ${at(0.90)} p95 ${at(0.95)} '
        'p99 ${at(0.99)} max ${at(1.0)} ms';
  }

  /// First index in [sorted] holding a value >= [value].
  int _lowerBound(List<int> sorted, int value) {
    int low = 0;
    int high = sorted.length;
    while (low < high) {
      final int mid = (low + high) ~/ 2;
      if (sorted[mid] < value) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }
}
