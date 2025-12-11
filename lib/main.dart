import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'screens/home.dart';
import 'screens/login.dart';
import 'providers/localization_provider.dart';
import 'providers/medication_provider.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('Environment variables loaded successfully');
  } catch (e) {
    debugPrint('Failed to load .env file: $e');
  }
  
  // Try to initialize Firebase, but continue if it fails
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    debugPrint('App will run without authentication. Make sure .env file exists with your Firebase credentials');
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocalizationProvider()),
        ChangeNotifierProvider(create: (_) => MedicationProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocalizationProvider, AuthProvider>(
      builder: (context, localizationProvider, authProvider, _) {
        // Always start with HomeScreen - authentication is optional
        // Users can sync data by tapping the "Sync your data?" button
        
        return MaterialApp(
          title: 'Easy Pill',
          locale: localizationProvider.locale,
          supportedLocales: LocalizationProvider.supportedLocales,
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
