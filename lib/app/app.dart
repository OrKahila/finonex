import 'package:flutter/material.dart';

import 'theme/pulse_theme.dart';

class PulseApp extends StatelessWidget {
  const PulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pulse',
      debugShowCheckedModeBanner: false,
      theme: buildPulseTheme(),
      home: const Scaffold(
        body: Center(child: Text('Pulse')),
      ),
    );
  }
}
