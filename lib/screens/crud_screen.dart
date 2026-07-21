import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_service.dart';
import '../db_service.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';

class CrudScreen extends StatefulWidget {
  const CrudScreen({super.key});
  @override
  State<CrudScreen> createState() => _CrudState();
}

class _CrudState extends State<CrudScreen> with SingleTickerProviderStateMixin {
  static const _green      = Color(0xFF1D9E75);
  static const _greenLight = Color(0xFFE1F5EE);
  static const _greenDark  = Color(0xFF0F6E56);
  static const _blue       = Color(0xFF1565C0);
  static const _blueLight  = Color(0xFFE3F2FD);
  static const _error      = Color(0xFFE24B4A);
  static const _errLight   = Color(0xFFFCEBEB);
  static const _muted      = Color(0xFF6B7280);

  late TabController _tabs;
  List<Map<String,dynamic>> _users    = [];
  List<Map<String,dynamic>> _lessons  = [];
  List<Map<String,dynamic>> _progress = [];
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
    setState(() => _loading = true);
    final email = context.read<AuthService>().email;
    final users    = await DBService.instance.getAllUsers();
    final lessons  = await DBService.instance.getAllLessons();
    final progress = await DBService.instance.getQuizHistory(email);
    if (mounted) setState(() {
      _users = users; _lessons = lessons; _progress = progress;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _green,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Data Manager', style: TextStyle(color: Colors.white, fontSize: 15)),
          Text('CRUD — Users · Lessons · Progress',
              style: TextStyle(color: Colors.white70, fontSize: 10)),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _load),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.people_outline,   size: 16), text: 'Users'),
            Tab(icon: Icon(Icons.book_outlined,    size: 16), text: 'Lessons'),
            Tab(icon: Icon(Icons.bar_chart_outlined,size: 16), text: 'Progress'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : TabBarView(controller: _tabs, children: [
        _UsersTab(users: _users, isDark: isDark, onRefresh: _load),
        _LessonsTab(lessons: _lessons, isDark: isDark, onRefresh: _load),
        _ProgressTab(progress: _progress, isDark: isDark, onRefresh: _load),
      ]),
    );
  }
}

class _UsersTab extends StatefulWidget {
  final List<Map<String,dynamic>> users;
  final bool isDark;
  final VoidCallback onRefresh;
  const _UsersTab({required this.users, required this.isDark, required this.onRefresh});
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  static const _green      = Color(0xFF1D9E75);
  static const _greenLight = Color(0xFFE1F5EE);
  static const _error      = Color(0xFFE24B4A);
  static const _errLight   = Color(0xFFFCEBEB);
  static const _muted      = Color(0xFF6B7280);

  String _search = '';

  Future<void> _showEditDialog(Map<String,dynamic>? user) async {
    final nameCtrl  = TextEditingController(text: user?['name'] as String? ?? '');
    final emailCtrl = TextEditingController(text: user?['email'] as String? ?? '');
    final passCtrl  = TextEditingController();
    final formKey   = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(user == null ? 'Add user' : 'Edit user',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full name', isDense: true),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null),
          const SizedBox(height: 10),
          TextFormField(controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', isDense: true),
              validator: (v) => v == null || !v.contains('@') ? 'Invalid email' : null),
          const SizedBox(height: 10),
          if (user == null)
            TextFormField(controller: passCtrl, obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', isDense: true),
                validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: _muted))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _green,
                  foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                if (user == null) {
                  await DBService.instance.registerUser(
                      nameCtrl.text.trim(), emailCtrl.text.trim(), passCtrl.text);
                } else {
                  await DBService.instance.updateUser(
                      user['email'] as String,
                      {'name': nameCtrl.text.trim(), 'email': emailCtrl.text.trim()});
                }
                if (ctx.mounted) Navigator.pop(ctx);
                widget.onRefresh();
              },
              child: Text(user == null ? 'Add' : 'Save')),
        ],
      ),
    );
    nameCtrl.dispose(); emailCtrl.dispose(); passCtrl.dispose();
  }

  Future<void> _confirmDelete(Map<String,dynamic> user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete user?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        content: Text('Delete "${user['name']}"? This also removes their activity and quiz history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: _muted))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _error,
                  foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await DBService.instance.deleteUser(user['email'] as String);
      widget.onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.users.where((u) =>
    _search.isEmpty ||
        (u['name'] as String).toLowerCase().contains(_search) ||
        (u['email'] as String).toLowerCase().contains(_search)).toList();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16,12,16,4),
        child: TextField(
          onChanged: (v) => setState(() => _search = v.toLowerCase()),
          decoration: _searchDec('Search users…'),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(children: [
          Text('${filtered.length} users', style: const TextStyle(fontSize: 12, color: _muted)),
        ]),
      ),
      Expanded(
        child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16,4,16,80),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final u    = filtered[i];
              final name = u['name'] as String;
              final email= u['email'] as String;
              return Dismissible(
                  key: Key('u-$email'),
                  direction: DismissDirection.endToStart,
                  background: _deleteBg(),
                  confirmDismiss: (_) async { await _confirmDelete(u); return false; },
                  child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                          color: widget.isDark ? const Color(0xFF1C1F26) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB))),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: _greenLight,
                            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(color: _green, fontWeight: FontWeight.w600))),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text(email, style: const TextStyle(fontSize: 12, color: _muted)),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(icon: const Icon(Icons.edit_outlined, color: _green, size: 18),
                              onPressed: () => _showEditDialog(u)),
                          IconButton(icon: const Icon(Icons.delete_outline, color: _error, size: 18),
                              onPressed: () => _confirmDelete(u)),
                        ]),
                      )));
            }),
      ),
      Padding(
          padding: const EdgeInsets.fromLTRB(16,0,16,16),
          child: SizedBox(width: double.infinity, height: 46,
              child: ElevatedButton.icon(
                  onPressed: () => _showEditDialog(null),
                  style: ElevatedButton.styleFrom(backgroundColor: _green,
                      foregroundColor: Colors.white, elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Add user')))),
    ]);
  }
}

class _LessonsTab extends StatefulWidget {
  final List<Map<String,dynamic>> lessons;
  final bool isDark;
  final VoidCallback onRefresh;
  const _LessonsTab({required this.lessons, required this.isDark, required this.onRefresh});
  @override
  State<_LessonsTab> createState() => _LessonsTabState();
}

class _LessonsTabState extends State<_LessonsTab> {
  static const _green      = Color(0xFF1D9E75);
  static const _greenLight = Color(0xFFE1F5EE);
  static const _error      = Color(0xFFE24B4A);
  static const _muted      = Color(0xFF6B7280);
  String _search = '';

  Future<void> _showEditDialog(Map<String,dynamic> lesson) async {
    final titleCtrl = TextEditingController(text: lesson['title'] as String? ?? '');
    final summCtrl  = TextEditingController(text: lesson['ai_summary'] as String? ?? '');
    final formKey   = GlobalKey<FormState>();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit lesson',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title', isDense: true),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null),
          const SizedBox(height: 10),
          TextFormField(controller: summCtrl, maxLines: 3,
              decoration: const InputDecoration(labelText: 'AI Summary', isDense: true)),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: _muted))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _green,
                  foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                await DBService.instance.updateLesson(lesson['id'] as String,
                    {'title': titleCtrl.text.trim(), 'ai_summary': summCtrl.text.trim()});
                if (ctx.mounted) Navigator.pop(ctx);
                widget.onRefresh();
              },
              child: const Text('Save')),
        ],
      ),
    );
    titleCtrl.dispose(); summCtrl.dispose();
  }

  Future<void> _confirmDelete(Map<String,dynamic> lesson) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete lesson?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        content: Text('Delete "${lesson['title']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: _muted))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _error,
                  foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await DBService.instance.deleteLesson(lesson['id'] as String);
      widget.onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.lessons.where((l) =>
    _search.isEmpty ||
        (l['title'] as String).toLowerCase().contains(_search) ||
        (l['course_title'] as String? ?? '').toLowerCase().contains(_search)).toList();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16,12,16,4),
        child: TextField(
          onChanged: (v) => setState(() => _search = v.toLowerCase()),
          decoration: _searchDec('Search lessons…'),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(children: [
          Text('${filtered.length} lessons', style: const TextStyle(fontSize: 12, color: _muted)),
        ]),
      ),
      Expanded(
        child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16,4,16,80),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final l    = filtered[i];
              final prog = (l['progress'] as num).toDouble();
              return Dismissible(
                  key: Key('l-${l['id']}'),
                  direction: DismissDirection.endToStart,
                  background: _deleteBg(),
                  confirmDismiss: (_) async { await _confirmDelete(l); return false; },
                  child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: widget.isDark ? const Color(0xFF1C1F26) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB))),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(color: _greenLight,
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text(l['course_title'] as String? ?? '',
                                  style: const TextStyle(fontSize: 9, color: Color(0xFF0F6E56),
                                      fontWeight: FontWeight.w500))),
                          const Spacer(),
                          IconButton(icon: const Icon(Icons.edit_outlined, color: _green, size: 18),
                              onPressed: () => _showEditDialog(l), padding: EdgeInsets.zero,
                              constraints: const BoxConstraints()),
                          const SizedBox(width: 8),
                          IconButton(icon: const Icon(Icons.delete_outline, color: _error, size: 18),
                              onPressed: () => _confirmDelete(l), padding: EdgeInsets.zero,
                              constraints: const BoxConstraints()),
                        ]),
                        const SizedBox(height: 6),
                        Text(l['title'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text('${l['read_minutes']} min · ${(prog*100).toStringAsFixed(0)}% done',
                            style: const TextStyle(fontSize: 11, color: _muted)),
                        const SizedBox(height: 8),
                        ClipRRect(borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(value: prog, minHeight: 4,
                                backgroundColor: _greenLight,
                                valueColor: const AlwaysStoppedAnimation(_green))),
                      ])));
            }),
      ),
    ]);
  }
}

class _ProgressTab extends StatelessWidget {
  final List<Map<String,dynamic>> progress;
  final bool isDark;
  final VoidCallback onRefresh;
  const _ProgressTab({required this.progress, required this.isDark, required this.onRefresh});

  static const _green      = Color(0xFF1D9E75);
  static const _greenLight = Color(0xFFE1F5EE);
  static const _error      = Color(0xFFE24B4A);
  static const _errLight   = Color(0xFFFCEBEB);
  static const _muted      = Color(0xFF6B7280);

  String _fmt(String iso) {
    final dt = DateTime.tryParse(iso) ?? DateTime.now();
    const months = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month]} ${dt.day}  ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (progress.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.bar_chart_outlined, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 8),
        const Text('No quiz progress yet', style: TextStyle(color: _muted)),
      ]));
    }
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Text('${progress.length} quiz attempts',
              style: const TextStyle(fontSize: 12, color: _muted)),
          const Spacer(),
          TextButton.icon(
              icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: _muted),
              label: const Text('Clear all', style: TextStyle(fontSize: 12, color: _muted)),
              onPressed: () async {
                for (final p in progress) {
                  await DBService.instance.deleteQuizAttempt(p['id'] as int);
                }
                onRefresh();
              }),
        ]),
      ),
      Expanded(
        child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16,0,16,80),
            itemCount: progress.length,
            itemBuilder: (ctx, i) {
              final p       = progress[i];
              final correct = (p['score'] as int) == 1;
              return Dismissible(
                  key: Key('p-${p['id']}'),
                  direction: DismissDirection.endToStart,
                  background: _deleteBg(),
                  onDismissed: (_) async {
                    await DBService.instance.deleteQuizAttempt(p['id'] as int);
                    onRefresh();
                  },
                  child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1C1F26) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: correct ? _green.withOpacity(0.3) : _error.withOpacity(0.3))),
                      child: Row(children: [
                        Icon(correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            color: correct ? _green : _error, size: 24),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p['lesson_title'] as String? ?? 'Quiz',
                                  style: const TextStyle(fontWeight: FontWeight.w500)),
                              Text(p['course_title'] as String? ?? '',
                                  style: const TextStyle(fontSize: 11, color: _muted)),
                              Text(_fmt(p['attempted_at'] as String),
                                  style: const TextStyle(fontSize: 10, color: _muted)),
                            ])),
                        Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: correct ? _greenLight : _errLight,
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(correct ? 'Correct' : 'Wrong',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                    color: correct ? _green : _error))),
                      ])));
            }),
      ),
    ]);
  }
}

InputDecoration _searchDec(String hint) => InputDecoration(
    hintText: hint,
    prefixIcon: const Icon(Icons.search, size: 20),
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1D9E75), width: 1.5)));

Widget _deleteBg() => Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 20),
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
        color: const Color(0xFFFCEBEB),
        borderRadius: BorderRadius.circular(14)),
    child: const Icon(Icons.delete_outline, color: Color(0xFFE24B4A)));