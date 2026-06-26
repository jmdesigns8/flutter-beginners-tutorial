import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'state/mileage_state.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => MileageState()..load(),
      child: const StriveApp(),
    ),
  );
}

class StriveApp extends StatelessWidget {
  const StriveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Strive',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE65100),
        ),
        useMaterial3: true,
        cardTheme: const CardTheme(elevation: 2),
      ),
      home: const HomeScreen(),
    );
  }
}
