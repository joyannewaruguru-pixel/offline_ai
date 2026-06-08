import 'package:flutter/material.dart';

class Course {
  final String id;
  final String title;
  final String subtitle;
  final double progress;
  final IconData icon;

  const Course({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.icon,
  });

  factory Course.placeholder() => const Course(
    id: 'placeholder',
    title: 'Loading...',
    subtitle: '',
    progress: 0,
    icon: Icons.book_outlined,
  );

  factory Course.fromMap(Map<String, dynamic> m) => Course(
    id: m['id'] as String,
    title: m['title'] as String,
    subtitle: m['subtitle'] as String,
    progress: (m['progress'] as num).toDouble(),
    icon: IconData(m['icon_code'] as int, fontFamily: 'MaterialIcons'),
  );
}