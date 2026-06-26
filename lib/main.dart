import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'state/mileage_state.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => MileageState()..load(),
      child: const MileageTrackerApp(),
    ),
  );
}

class MileageTrackerApp extends StatelessWidget {
  const MileageTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mileage Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
        ),
        useMaterial3: true,
        cardTheme: const CardTheme(elevation: 2),
      ),
      home: const HomeScreen(),
    );
  }
}
