import 'package:flutter/material.dart';

import 'screens/profile_select_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PokeMathApp());
}

class PokeMathApp extends StatelessWidget {
  const PokeMathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PokeMath',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFEE1515), // Pokéball-Rot
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            textStyle:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: const ProfileSelectScreen(),
    );
  }
}
