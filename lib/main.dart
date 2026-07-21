import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_service.dart';
import 'db_service.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/lesson_screen.dart';
import 'screens/ai_tutor_screen.dart';
import 'screens/crud_screen.dart';
import 'screens/activity_screen.dart';
import 'screens/gesture_demo_screen.dart';
import 'screens/device_features_screen.dart';
import 'screens/library_screen.dart';
import 'screens/rag_screen.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DBService.instance.init();
  await ThemeService.instance.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
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
    final ts = context.watch<ThemeService>();
    return MaterialApp(
      title: 'LearnAI',
      debugShowCheckedModeBanner: false,
      themeMode: ts.themeMode,
      theme:     ThemeService.light(),
      darkTheme: ThemeService.dark(),
      initialRoute: '/splash',
      routes: {
        '/splash'         : (_) => const SplashScreen(),
        '/onboarding'     : (_) => const OnboardingScreen(),
        '/login'          : (_) => const LoginScreen(),
        '/dashboard'      : (_) => const DashboardScreen(),
        '/lesson'         : (_) => const LessonScreen(),
        '/ai-tutor'       : (_) => const AiTutorScreen(),
        '/crud'           : (_) => const CrudScreen(),
        '/activity'       : (_) => const ActivityScreen(),
        '/gesture-demo'   : (_) => const GestureDemoScreen(),
        '/device-features': (_) => const DeviceFeaturesScreen(),
        '/library'        : (_) => const LibraryScreen(),
        '/rag'            : (_) => const RagScreen(),
      },
    );
  }
}