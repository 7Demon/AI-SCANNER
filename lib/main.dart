import 'package:flutter/material.dart';
import 'screens/scan_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AIScannApp());
}

class AIScannApp extends StatelessWidget {
  const AIScannApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIScann - QC Cetak Karung',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF004D40), // Deep Teal
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: const ScanScreen(),
    );
  }
}

