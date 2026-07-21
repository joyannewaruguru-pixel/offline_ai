import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'course_model.dart';
import 'lesson_model.dart';

class DBService {
  DBService._();
  static final DBService instance = DBService._();
  Database? _db;

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'learnai_v3.db'),
      version: 1,
      onCreate: _onCreate,
    );
    await _seedIfEmpty();
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''CREATE TABLE users(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      level INTEGER DEFAULT 0,
      avatar_path TEXT,
      face_id_path TEXT,
      created_at TEXT NOT NULL
    )''');

    await db.execute('''CREATE TABLE user_activity(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_email TEXT NOT NULL,
      action TEXT NOT NULL,
      detail TEXT,
      occurred_at TEXT NOT NULL
    )''');

    await db.execute('''CREATE TABLE courses(
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      subtitle TEXT NOT NULL,
      progress REAL DEFAULT 0,
      icon_code INTEGER NOT NULL
    )''');

    await db.execute('''CREATE TABLE lessons(
      id TEXT PRIMARY KEY,
      course_id TEXT NOT NULL,
      title TEXT NOT NULL,
      content TEXT NOT NULL,
      ai_summary TEXT NOT NULL,
      read_minutes INTEGER NOT NULL,
      progress REAL DEFAULT 0
    )''');

    await db.execute('''CREATE TABLE quiz_attempts(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      lesson_id TEXT NOT NULL,
      user_email TEXT NOT NULL,
      score INTEGER NOT NULL,
      attempted_at TEXT NOT NULL
    )''');

    await db.execute('''CREATE TABLE user_progress(
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )''');

    await db.execute('''CREATE TABLE rag_documents(
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      source TEXT NOT NULL,
      chunk_count INTEGER DEFAULT 0,
      created_at TEXT NOT NULL,
      user_email TEXT NOT NULL
    )''');

    await db.execute('''CREATE TABLE rag_chunks(
      id TEXT PRIMARY KEY,
      doc_id TEXT NOT NULL,
      doc_name TEXT NOT NULL,
      chunk_index INTEGER NOT NULL,
      text TEXT NOT NULL,
      embedding TEXT NOT NULL
    )''');

    await db.execute('''CREATE TABLE captured_documents(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_email TEXT NOT NULL,
      image_path TEXT NOT NULL,
      title TEXT,
      description TEXT,
      doc_type TEXT NOT NULL,
      captured_at TEXT NOT NULL
    )''');
  }

  Future<void> _seedIfEmpty() async {
    final n = Sqflite.firstIntValue(
        await _db!.rawQuery('SELECT COUNT(*) FROM courses')) ?? 0;
    if (n > 0) return;

    final courses = [
      {'id':'week1','title':'Intro to Mobile Dev','subtitle':'Week 1 · Flutter setup','progress':1.0,'icon_code':Icons.phone_android.codePoint},
      {'id':'week2','title':'Languages & Frameworks','subtitle':'Week 2 · Dart & Flutter','progress':1.0,'icon_code':Icons.code.codePoint},
      {'id':'week3','title':'UI Development','subtitle':'Week 3 · Widgets & Screens','progress':0.6,'icon_code':Icons.dashboard_outlined.codePoint},
      {'id':'week4','title':'Data Management','subtitle':'Week 4 · SQLite & SharedPrefs','progress':0.0,'icon_code':Icons.storage_outlined.codePoint},
      {'id':'week5','title':'Networking & APIs','subtitle':'Week 5 · REST & JSON','progress':0.0,'icon_code':Icons.cloud_outlined.codePoint},
      {'id':'week8','title':'Gestures & Input','subtitle':'Week 8 · OOP event handling','progress':0.0,'icon_code':Icons.touch_app_outlined.codePoint},
      {'id':'week9','title':'Device Features','subtitle':'Week 9 · Camera, GPS, Sensors','progress':0.0,'icon_code':Icons.sensors_outlined.codePoint},
      {'id':'week10','title':'Integration & Testing','subtitle':'Week 10 · QA & debugging','progress':0.0,'icon_code':Icons.bug_report_outlined.codePoint},
      {'id':'week11','title':'Deployment','subtitle':'Week 11 · APK & Play Store','progress':0.0,'icon_code':Icons.rocket_launch_outlined.codePoint},
      {'id':'php','title':'PHP Programming','subtitle':'Web dev · Kenya case study','progress':0.0,'icon_code':Icons.web_outlined.codePoint},
      {'id':'python','title':'Python Programming','subtitle':'Data & scripting · Kenyan context','progress':0.0,'icon_code':Icons.terminal_outlined.codePoint},
      {'id':'networks','title':'Computer Networks','subtitle':'Networking · Kenya infrastructure','progress':0.0,'icon_code':Icons.router_outlined.codePoint},
    ];
    for (final c in courses) {
      await _db!.insert('courses', c);
    }

    final lessons = _buildLessons();
    for (final l in lessons) {
      await _db!.insert('lessons', l);
    }

    await _db!.insert('user_progress', {'key':'streak','value':'3'});
    await _db!.insert('user_progress', {'key':'lessons_done','value':'6'});
    await _db!.insert('user_progress', {'key':'quiz_avg','value':'82'});
  }

  List<Map<String,dynamic>> _buildLessons() => [
    {
      'id':'week9_l1','course_id':'week9',
      'title':'Device Features — Camera, GPS & Sensors',
      'read_minutes':5,'progress':0.0,
      'ai_summary':'Smartphones have hardware (camera, GPS, sensors) that apps can access. Always request runtime permissions first. Use image_picker for camera and geolocator for GPS in Flutter.',
      'content':'''## Device Features Integration

Modern smartphones contain hardware apps can access directly.

### Common device features

| Feature | Purpose | Kenya example |
|---|---|---|
| Camera | Photos/video/scan | M-Pesa ID scanning during KYC |
| GPS | Location | Bolt/Uber driver tracking |
| Accelerometer | Movement | Safaricom fitness app step counter |
| Gyroscope | Rotation | Game tilt controls |
| Fingerprint | Authentication | KCB mobile banking login |
| NFC | Contactless | Matatu card tap payment |

### Android Permissions

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

### Camera in Flutter

```dart
import 'package:image_picker/image_picker.dart';

final picker = ImagePicker();
final file = await picker.pickImage(source: ImageSource.camera);
if (file != null) {
  setState(() => _image = File(file.path));
}
```

### GPS in Flutter

```dart
import 'package:geolocator/geolocator.dart';

final pos = await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.high,
);
print("Nairobi: lat=\${pos.latitude}, lng=\${pos.longitude}");
```

### Sensors in Flutter

```dart
import 'package:sensors_plus/sensors_plus.dart';

accelerometerEventStream().listen((AccelerometerEvent e) {
  print("X=\${e.x} Y=\${e.y} Z=\${e.z}");
});
```

> **Kenya case study:** eCitizen uses camera to scan Huduma Namba cards. Bolt uses GPS + accelerometer to detect trips and calculate fares. MPESA uses fingerprint/face biometrics for authentication.
''',
    },
    {
      'id':'week10_l1','course_id':'week10',
      'title':'Integration, Testing & Debugging',
      'read_minutes':5,'progress':0.0,
      'ai_summary':'Integration connects all app features together. Test each screen, button, and database operation. Use Flutter DevTools and print() for debugging.',
      'content':'''## Integration and Testing

### Integration Checklist

Before testing, confirm all parts of your app are connected:

```
✓ Screens are reachable via navigation routes
✓ Forms validate and submit data
✓ SQLite reads and writes correctly
✓ Camera and GPS permissions granted
✓ API calls have error handling
✓ Dark mode works across all screens
```

### Functional Testing

Test each feature works correctly:

| Feature | Test | Expected result |
|---|---|---|
| Login | Enter valid credentials | Navigates to dashboard |
| Register | Enter new email | Saved to SQLite users table |
| CRUD | Add a module | Appears in list immediately |
| Camera | Tap capture button | Photo saved to app storage |
| GPS | Tap get location | Shows Nairobi coordinates |
| Search | Type module name | List filters in real time |

### Non-functional Testing

| Test type | What to check |
|---|---|
| Performance | App opens in under 3 seconds |
| Reliability | App does not crash on bad input |
| Security | Passwords not in plain text |
| Usability | All buttons are tappable |
| Compatibility | Works on API 21+ |

### Common Bugs & Fixes

```dart
// Bug: MissingPluginException on image_picker
// Fix: flutter clean && flutter run

// Bug: Location permission denied crash
// Fix: Check permission before calling Geolocator
LocationPermission perm = await Geolocator.checkPermission();
if (perm == LocationPermission.denied) {
  perm = await Geolocator.requestPermission();
}

// Bug: SQLite column not found
// Fix: Delete app data to force _onCreate to re-run
// Settings → Apps → LearnAI → Clear Data
```

> **Best practice:** Always test on a physical Android device, not just the emulator. GPS and camera behave differently on real hardware.
''',
    },
    {
      'id':'week11_l1','course_id':'week11',
      'title':'APK Build & Play Store Deployment',
      'read_minutes':5,'progress':0.0,
      'ai_summary':'Build a release APK with flutter build apk --release. For Play Store use AAB format. Always remove debug code, add a proper icon, and set the correct app name first.',
      'content':'''## Deployment — APK & Play Store

### Before building

```yaml
# pubspec.yaml
version: 1.0.0+1   # version name + build number
```

```xml
<!-- AndroidManifest.xml -->
android:label="LearnAI"   <!-- app name on home screen -->
```

### Build APK (direct install)

```bash
# Debug APK (for testing)
flutter build apk --debug

# Release APK (for distribution)
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Build AAB (Google Play Store)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### App Icon

```yaml
# pubspec.yaml dev_dependencies
flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  image_path: "assets/images/learnai_logo.png"
  adaptive_icon_background: "#1D9E75"
```

```bash
dart run flutter_launcher_icons
flutter clean && flutter run
```

### Play Store Requirements

| Requirement | LearnAI value |
|---|---|
| App name | LearnAI |
| Short description | Offline AI learning for mobile dev students |
| Icon | 512×512 PNG |
| Screenshots | At least 2 phone screenshots |
| Privacy policy | Required if using camera/GPS |
| Category | Education |

> **Kenya context:** Google Play Store accepts M-Pesa as a payment method for app purchases, making it the primary distribution channel for Kenyan developers.
''',
    },
  ];

  Future<bool> registerUser(String name, String email, String password) async {
    try {
      await _db!.insert('users', {
        'name': name,
        'email': email,
        'password': password,
        'level': 0,
        'created_at': DateTime.now().toIso8601String(),
      });
      await logActivity(email, 'REGISTER', 'Account created');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String,dynamic>?> loginUser(String email, String password) async {
    final rows = await _db!.query('users',
        where: 'email = ? AND password = ?',
        whereArgs: [email, password], limit: 1);
    if (rows.isEmpty) return null;
    await logActivity(email, 'LOGIN', 'Signed in');
    return rows.first;
  }

  Future<List<Map<String,dynamic>>> getAllUsers() =>
      _db!.query('users', orderBy: 'created_at DESC');

  Future<bool> updateUser(String email, Map<String,dynamic> fields) async {
    try {
      await _db!.update('users', fields,
          where: 'email = ?', whereArgs: [email]);
      await logActivity(email, 'UPDATE', 'Profile updated');
      return true;
    } catch (_) { return false; }
  }

  Future<void> deleteUser(String email) async {
    await _db!.delete('users', where: 'email = ?', whereArgs: [email]);
    await _db!.delete('user_activity', where: 'user_email = ?', whereArgs: [email]);
    await _db!.delete('quiz_attempts', where: 'user_email = ?', whereArgs: [email]);
  }

  Future<Map<String,dynamic>?> getUserByEmail(String email) async {
    final rows = await _db!.query('users',
        where: 'email = ?', whereArgs: [email], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> saveAvatarPath(String email, String path) =>
      _db!.update('users', {'avatar_path': path},
          where: 'email = ?', whereArgs: [email]);

  Future<void> saveFaceIdPath(String email, String path) =>
      _db!.update('users', {'face_id_path': path},
          where: 'email = ?', whereArgs: [email]);

  Future<void> logActivity(String email, String action, [String? detail]) =>
      _db!.insert('user_activity', {
        'user_email': email,
        'action': action,
        'detail': detail,
        'occurred_at': DateTime.now().toIso8601String(),
      });

  Future<List<Map<String,dynamic>>> getUserActivity(String email, {int limit = 30}) =>
      _db!.query('user_activity',
          where: 'user_email = ?', whereArgs: [email],
          orderBy: 'occurred_at DESC', limit: limit);

  Future<List<Course>> getCourses() async {
    final rows = await _db!.query('courses', orderBy: 'id ASC');
    return rows.map(Course.fromMap).toList();
  }

  Future<int> insertCourse(Course c) => _db!.insert('courses', c.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> updateCourse(Course c) => _db!.update('courses', c.toMap(),
      where: 'id = ?', whereArgs: [c.id]);

  Future<void> deleteCourse(String id) =>
      _db!.delete('courses', where: 'id = ?', whereArgs: [id]);

  Future<Lesson?> getLesson(String courseId) async {
    final rows = await _db!.query('lessons',
        where: 'course_id = ?', whereArgs: [courseId], limit: 1);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return Lesson(
        id: r['id'] as String, title: r['title'] as String,
        subtitle: courseId, content: r['content'] as String,
        aiSummary: r['ai_summary'] as String,
        readMinutes: r['read_minutes'] as int,
        progress: (r['progress'] as num).toDouble());
  }

  Future<List<Map<String,dynamic>>> getAllLessons() =>
      _db!.rawQuery('''SELECT l.*, c.title as course_title
        FROM lessons l JOIN courses c ON l.course_id = c.id
        ORDER BY l.course_id, l.id''');

  Future<void> updateLesson(String id, Map<String,dynamic> fields) =>
      _db!.update('lessons', fields, where: 'id = ?', whereArgs: [id]);

  Future<void> deleteLesson(String id) =>
      _db!.delete('lessons', where: 'id = ?', whereArgs: [id]);

  Future<void> saveProgress(String lessonId, double progress) =>
      _db!.update('lessons', {'progress': progress},
          where: 'id = ?', whereArgs: [lessonId]);

  Future<void> saveQuizAttempt(String lessonId, int score, String email) =>
      _db!.insert('quiz_attempts', {
        'lesson_id': lessonId, 'user_email': email,
        'score': score, 'attempted_at': DateTime.now().toIso8601String(),
      });

  Future<List<Map<String,dynamic>>> getQuizHistory(String email) =>
      _db!.rawQuery('''SELECT qa.*, l.title as lesson_title, c.title as course_title
        FROM quiz_attempts qa
        LEFT JOIN lessons l ON qa.lesson_id = l.id
        LEFT JOIN courses c ON l.course_id = c.id
        WHERE qa.user_email = ?
        ORDER BY qa.attempted_at DESC''', [email]);

  Future<void> deleteQuizAttempt(int id) =>
      _db!.delete('quiz_attempts', where: 'id = ?', whereArgs: [id]);

  Future<Map<String,String>> getUserProgress() async {
    final rows = await _db!.query('user_progress');
    return {for (final r in rows) r['key'] as String: r['value'] as String};
  }

  Future<void> setUserProgress(String key, String value) =>
      _db!.insert('user_progress', {'key': key, 'value': value},
          conflictAlgorithm: ConflictAlgorithm.replace);

  Future<Map<String,dynamic>> getUserStats(String email) async {
    final attempts = await _db!.rawQuery(
        'SELECT COUNT(*) as total, SUM(score) as correct FROM quiz_attempts WHERE user_email = ?',
        [email]);
    final lessonsDone = await _db!.rawQuery(
        'SELECT COUNT(*) as cnt FROM lessons WHERE progress >= 1.0');
    final lastActivity = await _db!.query('user_activity',
        where: 'user_email = ?', whereArgs: [email],
        orderBy: 'occurred_at DESC', limit: 1);
    final total   = (attempts.first['total']   as int?) ?? 0;
    final correct = (attempts.first['correct'] as int?) ?? 0;
    final avg     = total > 0 ? (correct / total * 100).round() : 0;
    final done    = (lessonsDone.first['cnt'] as int?) ?? 0;
    final last    = lastActivity.isNotEmpty ? lastActivity.first['occurred_at'] as String : '';
    return {'quiz_total': total, 'quiz_avg': avg, 'lessons_done': done, 'last_active': last};
  }

  Future<int> saveCapturedDocument(String email, String imagePath,
      String title, String docType) async {
    return _db!.insert('captured_documents', {
      'user_email': email, 'image_path': imagePath,
      'title': title, 'doc_type': docType,
      'captured_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String,dynamic>>> getCapturedDocuments(String email) =>
      _db!.query('captured_documents',
          where: 'user_email = ?', whereArgs: [email],
          orderBy: 'captured_at DESC');

  Future<void> deleteCapturedDocument(int id) =>
      _db!.delete('captured_documents', where: 'id = ?', whereArgs: [id]);

  Future<void> insertRagDocument(Map<String,dynamic> doc) =>
      _db!.insert('rag_documents', doc, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> insertRagChunk(Map<String,dynamic> chunk) =>
      _db!.insert('rag_chunks', chunk, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<List<Map<String,dynamic>>> getRagChunks(String docId) =>
      _db!.query('rag_chunks', where: 'doc_id = ?', whereArgs: [docId]);

  Future<List<Map<String,dynamic>>> getAllRagChunks() =>
      _db!.query('rag_chunks');

  Future<List<Map<String,dynamic>>> getRagDocuments(String email) =>
      _db!.query('rag_documents',
          where: 'user_email = ?', whereArgs: [email],
          orderBy: 'created_at DESC');

  Future<void> deleteRagDocument(String docId) async {
    await _db!.delete('rag_documents', where: 'id = ?', whereArgs: [docId]);
    await _db!.delete('rag_chunks', where: 'doc_id = ?', whereArgs: [docId]);
  }

  Future<void> clearAllQuizHistory(String email) =>
      _db!.delete('quiz_attempts', where: 'user_email = ?', whereArgs: [email]);
}
