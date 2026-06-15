import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Splash screen shown for 2 seconds on app launch.
/// Decides whether to go to Onboarding or Dashboard.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashState();
}

class _SplashState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>    _fade;

  static const _green = Color(0xFF1D9E75);

  @override
  void initState() {
    super.initState();
    // Fade-in animation
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();

    // Navigate after 2.2 seconds
    Future.delayed(const Duration(milliseconds: 2200), _navigate);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  /// Checks SharedPreferences and routes to the right screen.
  Future<void> _navigate() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final done  = prefs.getBool('onboarding_done') ?? false;
    final token = prefs.getString('auth_token');

    if (!mounted) return;
    if (token != null) {
      // Already logged in → go straight to dashboard
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else if (done) {
      // Completed onboarding but not logged in → login
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      // First ever launch → onboarding
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _green,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App icon
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.psychology_rounded,
                    color: Colors.white, size: 48),
              ),
              const SizedBox(height: 20),
              const Text('LearnAI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  )),
              const SizedBox(height: 8),
              const Text('Offline AI Learning Platform',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 56),
              // Loading indicator
              SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text('BIT4107 · Mobile App Development',
                  style: TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}