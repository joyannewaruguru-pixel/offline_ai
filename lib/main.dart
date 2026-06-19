import 'package:flutter/material.dart';
import 'package:offline_ai/screens/splash%20screen.dart';
import 'package:provider/provider.dart';

import 'ai_tutor_screen.dart';
import 'auth_service.dart';
import 'dashboard_screen.dart';
import 'db_service.dart';
import 'lesson_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/lesson_screen.dart';
import 'screens/ai_tutor_screen.dart';
import 'screens/crud_screen.dart';
import 'screens/activity_screen.dart';
import 'services/auth_service.dart';
import 'services/db_service.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialise database FIRST — screens depend on it
  await DBService.instance.init();
  // Initialise theme — reads saved dark/light preference
  await ThemeService.instance.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        // ThemeService drives the dark/light switch across the whole app
        ChangeNotifierProvider(create: (_) => ThemeService.instance),
      ],
      child: const LearnAIApp(),
    ),
  );
}

class LearnAIApp extends StatelessWidget {
  const LearnAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to ThemeService so the app rebuilds when mode changes
    final themeService = context.watch<ThemeService>();

    return MaterialApp(
      title: 'LearnAI',
      debugShowCheckedModeBanner: false,
      // Switch between light and dark using ThemeService
      themeMode: themeService.themeMode,
      theme:     ThemeService.light(),
      darkTheme: ThemeService.dark(),
      initialRoute: '/splash',
      routes: {
        '/splash'    : (_) => const SplashScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/login'     : (_) => const LoginScreen(),
        '/dashboard' : (_) => const DashboardScreen(),
        '/lesson'    : (_) => const LessonScreen(),
        '/ai-tutor'  : (_) => const AiTutorScreen(),
        '/crud'      : (_) => const CrudScreen(),
        '/activity'  : (_) => const ActivityScreen(),
      },
    );
  }
}