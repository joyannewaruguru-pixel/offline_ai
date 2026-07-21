import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GreetingInfo {
  final String   greeting;
  final String   emoji;
  final String   subtext;
  final Color    bgTop;
  final Color    bgBottom;
  final IconData greetIcon;

  const GreetingInfo({
    required this.greeting,
    required this.emoji,
    required this.subtext,
    required this.bgTop,
    required this.bgBottom,
    required this.greetIcon,
  });
}

class TimeService {
  TimeService._();
  static final TimeService instance = TimeService._();

  static const String _apiUrl =
      'http://worldtimeapi.org/api/timezone/Africa/Nairobi';

  Future<GreetingInfo> getGreeting() async {
    final int hour = await _currentHour();
    return _infoForHour(hour);
  }

  Future<int> _currentHour() async {
    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
        final String datetimeStr = body['datetime'] as String;
        return DateTime.parse(datetimeStr).hour;
      }
    } catch (_) {}
    return DateTime.now().hour;
  }

  GreetingInfo _infoForHour(int hour) {
    if (hour >= 5 && hour < 12) {
      return const GreetingInfo(
        greeting:  'Good morning',
        emoji:     '🌅',
        subtext:   'Ready to learn something new today?',
        bgTop:     Color(0xFF9E531D),
        bgBottom:  Color(0xFF786415),
        greetIcon: Icons.wb_sunny_outlined,
      );
    }
    if (hour >= 12 && hour < 17) {
      return const GreetingInfo(
        greeting:  'Good afternoon',
        emoji:     '☀️',
        subtext:   'Keep the momentum going!',
        bgTop:     Color(0xFF1565C0),
        bgBottom:  Color(0xFF0D47A1),
        greetIcon: Icons.wb_cloudy_outlined,
      );
    }
    if (hour >= 17 && hour < 21) {
      return const GreetingInfo(
        greeting:  'Good evening',
        emoji:     '🌇',
        subtext:   'Wind down with a quick revision.',
        bgTop:     Color(0xFF6A1B9A),
        bgBottom:  Color(0xFF4A148C),
        greetIcon: Icons.nights_stay_outlined,
      );
    }
    return const GreetingInfo(
      greeting:  'Good night',
      emoji:     '🌙',
      subtext:   'Still studying? Take care of yourself.',
      bgTop:     Color(0xFF1A237E),
      bgBottom:  Color(0xFF0D1259),
      greetIcon: Icons.bedtime_outlined,
    );
  }
}