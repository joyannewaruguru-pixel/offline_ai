import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/course_model.dart';
import '../models/lesson_model.dart';
import 'course_model.dart';
import 'lesson_model.dart';

class DBService {
  DBService._();
  static final DBService instance = DBService._();
  Database? _db;

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'learnai.db'),
      version: 1,
      onCreate: _onCreate,
    );
    await _seedIfEmpty();
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE courses (
        id        TEXT PRIMARY KEY,
        title     TEXT NOT NULL,
        subtitle  TEXT NOT NULL,
        progress  REAL DEFAULT 0,
        icon_code INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE lessons (
        id           TEXT PRIMARY KEY,
        course_id    TEXT NOT NULL,
        title        TEXT NOT NULL,
        content      TEXT NOT NULL,
        ai_summary   TEXT NOT NULL,
        read_minutes INTEGER NOT NULL,
        progress     REAL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE quiz_attempts (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        lesson_id    TEXT NOT NULL,
        score        INTEGER NOT NULL,
        attempted_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _seedIfEmpty() async {
    final n = Sqflite.firstIntValue(
        await _db!.rawQuery('SELECT COUNT(*) FROM courses')) ?? 0;
    if (n > 0) return;

    final seeds = [
      {
        'id': 'week1',
        'title': 'Intro to Mobile Dev',
        'subtitle': 'Week 1 · 4 lessons',
        'progress': 1.0,
        'icon_code': Icons.phone_android.codePoint,
      },
      {
        'id': 'week2',
        'title': 'Languages & Frameworks',
        'subtitle': 'Week 2 · 5 lessons',
        'progress': 1.0,
        'icon_code': Icons.code.codePoint,
      },
      {
        'id': 'week3',
        'title': 'UI Development',
        'subtitle': 'Week 3 · In progress',
        'progress': 0.4,
        'icon_code': Icons.dashboard_outlined.codePoint,
      },
    ];

    for (final c in seeds) {
      await _db!.insert('courses', c);
    }
  }

  Future<List<Course>> getCourses() async {
    final rows = await _db!.query('courses');
    return rows.map(Course.fromMap).toList();
  }

  Future<Lesson?> getLesson(String courseId) async {
    final rows = await _db!.query(
      'lessons',
      where: 'course_id = ?',
      whereArgs: [courseId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return Lesson(
      id:          r['id'] as String,
      title:       r['title'] as String,
      subtitle:    courseId,
      content:     r['content'] as String,
      aiSummary:   r['ai_summary'] as String,
      readMinutes: r['read_minutes'] as int,
      progress:    (r['progress'] as num).toDouble(),
    );
  }

  Future<void> saveProgress(String lessonId, double progress) async {
    await _db!.update(
      'lessons',
      {'progress': progress},
      where: 'id = ?',
      whereArgs: [lessonId],
    );
  }

  Future<void> saveQuizAttempt(String lessonId, int score) async {
    await _db!.insert('quiz_attempts', {
      'lesson_id':    lessonId,
      'score':        score,
      'attempted_at': DateTime.now().toIso8601String(),
    });
  }
}