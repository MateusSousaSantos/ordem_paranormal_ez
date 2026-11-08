import 'package:flutter/material.dart';

import 'ui/home_screen.dart';

void main() {
  runApp(const OpEzApp());
}

class OpEzApp extends StatelessWidget {
  const OpEzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Op.ez',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7A1F2B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
