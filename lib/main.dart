import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ai_tutor_screen.dart';
import 'auth_service.dart';
import 'dashboard_screen.dart';
import 'db_service.dart';
import 'lesson_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/lesson_screen.dart';
import 'screens/ai_tutor_screen.dart';
import 'services/auth_service.dart';
import 'services/db_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DBService.instance.init();
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthService())],
      child: const LearnAIApp(),
    ),
  );
}

class LearnAIApp extends StatelessWidget {
  const LearnAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LearnAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1D9E75)),
        scaffoldBackgroundColor: const Color(0xFFF6F8F7),
      ),
      initialRoute: '/onboarding',
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/login'     : (_) => const LoginScreen(),
        '/dashboard' : (_) => const DashboardScreen(),
        '/lesson'    : (_) => const LessonScreen(),
        '/ai-tutor'  : (_) => const AiTutorScreen(),
      },
    );
  }
}