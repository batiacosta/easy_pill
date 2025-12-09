import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home.dart';
import 'providers/localization_provider.dart';
import 'l10n/app_strings.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocalizationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationProvider>(
      builder: (context, localizationProvider, _) {
        return MaterialApp(
          title: 'Easy Pill',
          locale: localizationProvider.locale,
          supportedLocales: AppLocalization.supportedLocales,
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
      },
    );
  }
}
