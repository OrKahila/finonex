import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/di/injector.dart';
import 'core/frame_report.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  // No-op outside profile builds.
  FrameReport().start();
  runApp(const PulseApp());
}
