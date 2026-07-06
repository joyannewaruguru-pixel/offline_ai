import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'db_service.dart';
import 'services/theme_service.dart';
import 'screens/splash screen.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'lesson_screen.dart';
import 'ai_tutor_screen.dart';
import 'screens/crud_screen.dart';
import 'screens/activity_screen.dart';
import 'screens/quizhistory_screen.dart';
import 'screens/device_features_screen.dart';
import'services/gestures/gesture_demo_screen.dart';

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
    final themeService = context.watch<ThemeService>();

    return MaterialApp(
      title: 'LearnAI',
      debugShowCheckedModeBanner: false,
      themeMode: themeService.themeMode,
      theme:     ThemeService.light(),
      darkTheme: ThemeService.dark(),
      initialRoute: '/splash',
      routes: {
        '/splash'       : (_) => const SplashScreen(),
        '/onboarding'   : (_) => const OnboardingScreen(),
        '/login'        : (_) => const LoginScreen(),
        '/dashboard'    : (_) => const DashboardScreen(),
        '/lesson'       : (_) => const LessonScreen(),
        '/ai-tutor'     : (_) => const AiTutorScreen(),
        '/crud'         : (_) => const CrudScreen(),
        '/activity'     : (_) => const ActivityScreen(),
        '/quiz-history' : (_) => const QuizHistoryScreen(),
        '/device-features': (_) => const DeviceFeaturesScreen(),
        '/gesture-demo' : (_) => const GestureDemoScreen(),
      },
    );
  }
}
