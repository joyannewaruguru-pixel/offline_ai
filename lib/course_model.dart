import 'package:flutter/material.dart';

class Course {
  final String id, title, subtitle;
  final double progress;
  final IconData icon;

  const Course({required this.id, required this.title, required this.subtitle, required this.progress, required this.icon});

  factory Course.placeholder() => const Course(id: 'placeholder', title: 'Loading...', subtitle: '', progress: 0, icon: Icons.book_outlined);

  factory Course.fromMap(Map<String, dynamic> m) {
    return Course(
      id: m['id'] as String,
      title: m['title'] as String,
      subtitle: m['subtitle'] as String,
      progress: (m['progress'] as num).toDouble(),
      // ignore: non_const_argument_for_const_parameter
      icon: IconData(m['icon_code'] as int, fontFamily: 'MaterialIcons'),
    );
  }

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'subtitle': subtitle, 'progress': progress, 'icon_code': icon.codePoint};

  Course copyWith({String? title, String? subtitle, double? progress, IconData? icon}) =>
      Course(id: id, title: title ?? this.title, subtitle: subtitle ?? this.subtitle, progress: progress ?? this.progress, icon: icon ?? this.icon);
}
