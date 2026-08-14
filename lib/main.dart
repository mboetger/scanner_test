import 'package:flutter/material.dart';
import 'views/scanner_screen.dart';

void main() {
  runApp(const ScannerApp());
}

/// Root application widget configuring Material Design theme and routing to [ScannerScreen].
class ScannerApp extends StatelessWidget {
  /// Creates the [ScannerApp].
  const ScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'mDNS Network Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(
            0xFF1E88E5, // Primary blue seed color (Hex: #1E88E5)
          ),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(
            0xFF1E88E5, // Primary blue seed color (Hex: #1E88E5)
          ),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const ScannerScreen(),
    );
  }
}
