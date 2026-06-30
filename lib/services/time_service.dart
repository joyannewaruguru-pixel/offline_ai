import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GreetingInfo {
  final String greeting;
  final String emoji;
  final String subtext;
  final IconData greetIcon;
  final Color bgTop;
  final Color bgBottom;

  GreetingInfo({
    required this.greeting,
    required this.emoji,
    required this.subtext,
    required this.greetIcon,
    required this.bgTop,
    required this.bgBottom,
  });
}

class TimeService {
  TimeService._();
  static final TimeService instance = TimeService._();

  Future<GreetingInfo> getGreeting() async {
    int hour = DateTime.now().hour;
    
    try {
      // Using a more reliable way to get time or fallback
      final res = await http.get(Uri.parse('http://worldtimeapi.org/api/timezone/Africa/Nairobi'))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final datetime = DateTime.parse(data['datetime']);
        hour = datetime.hour;
      }
    } catch (_) {
      // Fallback to local device time if API fails
      hour = DateTime.now().hour;
    }

    if (hour >= 5 && hour < 12) {
      return GreetingInfo(
        greeting: 'Good morning',
        emoji: '🌅',
        subtext: 'Start your learning journey today',
        greetIcon: Icons.wb_sunny_outlined,
        bgTop: const Color(0xFF1D9E75),
        bgBottom: const Color(0xFF15785A),
      );
    } else if (hour >= 12 && hour < 17) {
      return GreetingInfo(
        greeting: 'Good afternoon',
        emoji: '☀️',
        subtext: 'Keep up the great progress',
        greetIcon: Icons.wb_sunny,
        bgTop: const Color(0xFF1565C0),
        bgBottom: const Color(0xFF0D47A1),
      );
    } else if (hour >= 17 && hour < 21) {
      return GreetingInfo(
        greeting: 'Good evening',
        emoji: '🌇',
        subtext: 'Review what you learned today',
        greetIcon: Icons.wb_twilight,
        bgTop: const Color(0xFF6A1B9A),
        bgBottom: const Color(0xFF4A148C),
      );
    } else {
      return GreetingInfo(
        greeting: 'Good night',
        emoji: '🌙',
        subtext: 'Rest well for tomorrow\'s lessons',
        greetIcon: Icons.bedtime_outlined,
        bgTop: const Color(0xFF1A237E),
        bgBottom: const Color(0xFF121858),
      );
    }
  }
}
