import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/course_model.dart';
import '../models/lesson_model.dart';
import 'course_model.dart';
import 'lesson_model.dart';

/// Singleton database service.
/// Call [init] once in main() before runApp().
/// Access anywhere via [DBService.instance].
class DBService {
  DBService._();
  static final DBService instance = DBService._();
  Database? _db;

  // ── Open / create ──────────────────────────────────────────────────────────

  /// Opens learnai.db (creates it on first launch).
  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'learnai.db'),
      version: 1,
      onCreate: _onCreate,
    );
    await _seedIfEmpty();
  }

  /// Creates all tables. Runs ONLY on the very first launch.
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

    await db.execute('''
      CREATE TABLE user_progress (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // ── Seed default data ──────────────────────────────────────────────────────

  /// Inserts starter courses and lessons on first launch.
  Future<void> _seedIfEmpty() async {
    final n = Sqflite.firstIntValue(
        await _db!.rawQuery('SELECT COUNT(*) FROM courses')) ?? 0;
    if (n > 0) return; // already seeded

    // ── Courses ──────────────────────────────────────────────────────────────
    final courses = [
      {
        'id': 'week1', 'title': 'Intro to Mobile Dev',
        'subtitle': 'Week 1 · 4 lessons', 'progress': 1.0,
        'icon_code': Icons.phone_android.codePoint,
      },
      {
        'id': 'week2', 'title': 'Languages & Frameworks',
        'subtitle': 'Week 2 · 5 lessons', 'progress': 1.0,
        'icon_code': Icons.code.codePoint,
      },
      {
        'id': 'week3', 'title': 'UI Development',
        'subtitle': 'Week 3 · In progress', 'progress': 0.4,
        'icon_code': Icons.dashboard_outlined.codePoint,
      },
      {
        'id': 'week4', 'title': 'Data Management',
        'subtitle': 'Week 4 · SQLite & SharedPrefs', 'progress': 0.0,
        'icon_code': Icons.storage_outlined.codePoint,
      },
      {
        'id': 'week5', 'title': 'Networking & APIs',
        'subtitle': 'Week 5 · REST & JSON', 'progress': 0.0,
        'icon_code': Icons.cloud_outlined.codePoint,
      },
    ];
    for (final c in courses) {
      await _db!.insert('courses', c);
    }

    // ── Lessons ───────────────────────────────────────────────────────────────
    final lessons = [
      {
        'id': 'week3_lesson1',
        'course_id': 'week3',
        'title': 'Flutter Widgets',
        'read_minutes': 3,
        'progress': 0.6,
        'ai_summary':
        'StatelessWidget = printed photo (never changes). '
            'StatefulWidget = live video feed (rebuilds on setState).',
        'content': '''
## Stateless vs Stateful Widgets

Every UI element in Flutter is a **widget**. There are two main types.

### StatelessWidget
Builds once and never rebuilds. Use for fixed content — labels, icons, cards.

```dart
class GreetingCard extends StatelessWidget {
  final String name;
  const GreetingCard({required this.name});
  @override
  Widget build(BuildContext context) => Text('Hello, \$name!');
}
```

### StatefulWidget
Can call `setState()` to rebuild. Use for forms, toggles, counters.

```dart
class Counter extends StatefulWidget {
  @override
  State<Counter> createState() => _CounterState();
}
class _CounterState extends State<Counter> {
  int _n = 0;
  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: () => setState(() => _n++),
    child: Text('Tapped \$_n times'),
  );
}
```

**Rule of thumb:** start Stateless. Switch to Stateful only when the widget must change after it is first drawn.
''',
      },
      {
        'id': 'week4_lesson1',
        'course_id': 'week4',
        'title': 'SQLite Basics',
        'read_minutes': 4,
        'progress': 0.0,
        'ai_summary':
        'SQLite stores data as a file on the device. '
            'Use sqflite package. Always call init() in main() before runApp().',
        'content': '''
## SQLite in Flutter

SQLite is a full database engine stored as a single file on the device. No server needed.

### Setup
Add to pubspec.yaml:
```yaml
sqflite: ^2.3.3
path: ^1.9.0
```

### Open the database
```dart
final db = await openDatabase(
  join(await getDatabasesPath(), 'app.db'),
  version: 1,
  onCreate: (db, v) async {
    await db.execute(
      "CREATE TABLE notes (id INTEGER PRIMARY KEY, text TEXT)"
    );
  },
);
```

### CRUD operations
- **Create:** `db.insert('notes', {'text': 'Hello'})`
- **Read:** `db.query('notes')`
- **Update:** `db.update('notes', {'text': 'Hi'}, where: 'id=?', whereArgs: [1])`
- **Delete:** `db.delete('notes', where: 'id=?', whereArgs: [1])`
''',
      },
      {
        'id': 'week5_lesson1',
        'course_id': 'week5',
        'title': 'REST APIs & HTTP',
        'read_minutes': 4,
        'progress': 0.0,
        'ai_summary':
        'HTTP GET fetches data. HTTP POST sends data. '
            'Always use async/await and wrap in try/catch.',
        'content': '''
## REST APIs in Flutter

A REST API is a web service you communicate with over HTTP.

### Add the package
```yaml
http: ^1.2.2
```

### GET request
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

final res = await http.get(
  Uri.parse('https://jsonplaceholder.typicode.com/users'),
);
if (res.statusCode == 200) {
  final List data = jsonDecode(res.body);
  // data is a List of Maps
}
```

### POST request
```dart
final res = await http.post(
  Uri.parse('https://api.example.com/messages'),
  headers: {'content-type': 'application/json'},
  body: jsonEncode({'message': 'Hello'}),
);
```

### Always handle errors
```dart
try {
  final res = await http.get(uri).timeout(Duration(seconds: 10));
  if (res.statusCode == 200) { /* success */ }
  else { /* server error */ }
} catch (e) {
  // network error
} finally {
  setState(() => _loading = false);
}
```
''',
      },
    ];
    for (final l in lessons) {
      await _db!.insert('lessons', l);
    }

    // ── Default user progress ─────────────────────────────────────────────────
    await _db!.insert('user_progress', {'key': 'streak',      'value': '3'});
    await _db!.insert('user_progress', {'key': 'lessons_done','value': '6'});
    await _db!.insert('user_progress', {'key': 'quiz_avg',    'value': '82'});
  }

  // ── COURSES ────────────────────────────────────────────────────────────────

  /// Returns all courses ordered by id.
  Future<List<Course>> getCourses() async {
    final rows = await _db!.query('courses', orderBy: 'id ASC');
    return rows.map(Course.fromMap).toList();
  }

  /// Inserts a new course. Returns the row id.
  Future<int> insertCourse(Course c) => _db!.insert(
    'courses', c.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  /// Updates an existing course row.
  Future<void> updateCourse(Course c) => _db!.update(
    'courses', c.toMap(),
    where: 'id = ?', whereArgs: [c.id],
  );

  /// Deletes a course by id.
  Future<void> deleteCourse(String id) => _db!.delete(
    'courses', where: 'id = ?', whereArgs: [id],
  );

  // ── LESSONS ────────────────────────────────────────────────────────────────

  /// Returns the first lesson for a given course id.
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

  /// Saves the reading progress (0.0 – 1.0) for a lesson.
  Future<void> saveProgress(String lessonId, double progress) =>
      _db!.update('lessons', {'progress': progress},
          where: 'id = ?', whereArgs: [lessonId]);

  // ── QUIZ ATTEMPTS ──────────────────────────────────────────────────────────

  /// Saves a quiz attempt (score 0 or 1) for a lesson.
  Future<void> saveQuizAttempt(String lessonId, int score) =>
      _db!.insert('quiz_attempts', {
        'lesson_id':    lessonId,
        'score':        score,
        'attempted_at': DateTime.now().toIso8601String(),
      });

  /// Returns all quiz attempts ordered newest first.
  Future<List<Map<String, dynamic>>> getQuizHistory() =>
      _db!.rawQuery(
        '''SELECT qa.id, qa.lesson_id, qa.score, qa.attempted_at,
                  l.title as lesson_title
           FROM quiz_attempts qa
           LEFT JOIN lessons l ON qa.lesson_id = l.id
           ORDER BY qa.attempted_at DESC''',
      );

  /// Deletes a single quiz attempt by id.
  Future<void> deleteQuizAttempt(int id) =>
      _db!.delete('quiz_attempts', where: 'id = ?', whereArgs: [id]);

  /// Clears all quiz history.
  Future<void> clearAllQuizHistory() => _db!.delete('quiz_attempts');

  // ── USER PROGRESS ──────────────────────────────────────────────────────────

  /// Returns a key-value map of all user progress stats.
  Future<Map<String, String>> getUserProgress() async {
    final rows = await _db!.query('user_progress');
    return {for (final r in rows) r['key'] as String: r['value'] as String};
  }

  /// Sets a single progress value (inserts or replaces).
  Future<void> setUserProgress(String key, String value) =>
      _db!.insert('user_progress', {'key': key, 'value': value},
          conflictAlgorithm: ConflictAlgorithm.replace);

  /// Increments the lessons_done counter by 1.
  Future<void> incrementLessonsDone() async {
    final prog = await getUserProgress();
    final current = int.tryParse(prog['lessons_done'] ?? '0') ?? 0;
    await setUserProgress('lessons_done', '${current + 1}');
  }
}