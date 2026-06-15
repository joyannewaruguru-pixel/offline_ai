import 'package:flutter/material.dart';

/// Represents a weekly course module stored in SQLite.
class Course {
  final String   id;
  final String   title;
  final String   subtitle;
  final double   progress;  // 0.0 – 1.0
  final IconData icon;

  const Course({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.icon,
  });

  /// Fallback used while data is loading.
  factory Course.placeholder() => const Course(
    id: 'placeholder', title: 'Loading...', subtitle: '',
    progress: 0, icon: Icons.book_outlined,
  );

  /// Creates a Course from a SQLite row map.
  factory Course.fromMap(Map<String, dynamic> m) => Course(
    id:       m['id']       as String,
    title:    m['title']    as String,
    subtitle: m['subtitle'] as String,
    progress: (m['progress'] as num).toDouble(),
    icon: IconData(m['icon_code'] as int, fontFamily: 'MaterialIcons'),
  );

  /// Converts to a map for SQLite insert / update.
  Map<String, dynamic> toMap() => {
    'id':        id,
    'title':     title,
    'subtitle':  subtitle,
    'progress':  progress,
    'icon_code': icon.codePoint,
  };

  /// Returns a copy with changed fields — used for edit operations.
  Course copyWith({
    String?   title,
    String?   subtitle,
    double?   progress,
    IconData? icon,
  }) => Course(
    id:       id,
    title:    title    ?? this.title,
    subtitle: subtitle ?? this.subtitle,
    progress: progress ?? this.progress,
    icon:     icon     ?? this.icon,
  );
}