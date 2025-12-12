import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'screens/home.dart';
import 'providers/localization_provider.dart';
import 'providers/medication_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/sync_provider.dart';
import 'utilities/app_colors.dart';

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
        ChangeNotifierProvider(create: (_) => SyncProvider()),
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
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              tertiary: AppColors.danger,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
              error: AppColors.danger,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.background,
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
