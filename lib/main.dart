import 'package:examis_ai/core/secrets.dart';
import 'package:examis_ai/pages/onboarding_screens.dart';
import 'package:examis_ai/pages/splash_screen.dart';
import 'package:examis_ai/provider/auth_provider.dart';
import 'package:examis_ai/provider/history_provider.dart';
import 'package:examis_ai/provider/theme_provider.dart';
import 'package:examis_ai/theming/app_colors.dart';
import 'package:examis_ai/theming/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'provider/app_state_provider.dart';
import 'provider/assessment_provider.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Supabase.initialize(
    url: AppSecrets.supabaseURL,
    anonKey: AppSecrets.supabaseApiKey,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => AssessmentProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );

  FlutterNativeSplash.remove();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. WATCH THE THEME PROVIDER
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Examis AI',

      // 2. CONNECT YOUR CUSTOM THEMES HERE!
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,

      home: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          if (appState.isLoading) {
            // Updated to use the dynamic context background
            return Scaffold(
              backgroundColor: context.background,
              body: const Center(child: CircularProgressIndicator()),
            );
          }
          return appState.hasSeenOnboarding
              ? const SplashScreen()
              : const OnboardingScreen();
        },
      ),
    );
  }
}