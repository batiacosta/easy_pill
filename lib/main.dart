import 'package:flutter/material.dart';
import 'screens/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easy Pill',
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF9B51E0),
          secondary: const Color(0xFF2D9CDB),
          tertiary: const Color(0xFFEB5757),
          surface: const Color(0xFF1E1E1E),
          onSurface: const Color(0xFFE0E0E0),
          error: const Color(0xFFEB5757),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
    );
  }
}
