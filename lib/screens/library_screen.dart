import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_service.dart';
import '../db_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryState();
}

class _LibraryState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  static const _green      = Color(0xFF1D9E75);
  static const _greenLight = Color(0xFFE1F5EE);

  late TabController _tabs;
  List<Map<String,dynamic>> _lessons    = [];
  List<Map<String,dynamic>> _history    = [];
  Map<String,dynamic>       _stats      = {};
  Map<String,dynamic>?      _userProfile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    final email = context.read<AuthService>().email;
    final lessons = await DBService.instance.getAllLessons();
    final history = await DBService.instance.getQuizHistory(email);
    final stats   = await DBService.instance.getUserStats(email);
    final profile = await DBService.instance.getUserByEmail(email);
    if (mounted) setState(() {
      _lessons = lessons; _history = history;
      _stats = stats; _userProfile = profile;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        backgroundColor: _green,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(controller: _tabs, labelColor: Colors.white, unselectedLabelColor: Colors.white60, indicatorColor: Colors.white,
          tabs: const [Tab(text: 'Lessons'), Tab(text: 'History'), Tab(text: 'Progress')],
        ),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator(color: _green))
          : TabBarView(controller: _tabs, children: [
        _LessonsTab(lessons: _lessons, isDark: isDark),
        _HistoryTab(history: _history, isDark: isDark, onDelete: _deleteAttempt),
        _ProgressTab(stats: _stats, profile: _userProfile, lessons: _lessons, isDark: isDark),
      ]),
    );
  }

  Future<void> _deleteAttempt(int id) async {
    await DBService.instance.deleteQuizAttempt(id);
    _load();
  }
}

class _LessonsTab extends StatefulWidget {
  final List<Map<String,dynamic>> lessons; final bool isDark;
  const _LessonsTab({required this.lessons, required this.isDark});
  @override
  State<_LessonsTab> createState() => _LessonsTabState();
}

class _LessonsTabState extends State<_LessonsTab> {
  static const _green = Color(0xFF1D9E75);
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.lessons.where((l) => (l['title'] as String).toLowerCase().contains(_search)).toList();
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: TextField(onChanged: (v) => setState(() => _search = v.toLowerCase()), decoration: const InputDecoration(hintText: 'Search...'))),
      Expanded(child: ListView.builder(itemCount: filtered.length, itemBuilder: (ctx, i) {
        final l = filtered[i]; final prog = (l['progress'] as num).toDouble();
        return ListTile(title: Text(l['title']), subtitle: Text('${(prog*100).toInt()}% complete'), onTap: () => Navigator.pushNamed(ctx, '/lesson', arguments: {'courseId': l['course_id']}));
      })),
    ]);
  }
}

class _HistoryTab extends StatelessWidget {
  final List<Map<String,dynamic>> history; final bool isDark; final void Function(int) onDelete;
  const _HistoryTab({required this.history, required this.isDark, required this.onDelete});
  @override
  Widget build(BuildContext context) => ListView.builder(itemCount: history.length, itemBuilder: (ctx, i) => ListTile(title: Text(history[i]['lesson_title'] ?? 'Quiz'), trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => onDelete(history[i]['id']))));
}

class _ProgressTab extends StatelessWidget {
  final Map<String,dynamic> stats; final Map<String,dynamic>? profile; final List<Map<String,dynamic>> lessons; final bool isDark;
  const _ProgressTab({required this.stats, required this.profile, required this.lessons, required this.isDark});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Progress and Stats'));
}
