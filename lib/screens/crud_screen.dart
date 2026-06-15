import 'package:flutter/material.dart';
import '../course_model.dart';
import '../db_service.dart';
import '../models/course_model.dart';
import '../services/db_service.dart';

/// Week 4 assignment — demonstrates full CRUD on the courses table.
/// Add a new module, edit its title/subtitle, delete it,
/// and search the list. All changes persist in SQLite.
class CrudScreen extends StatefulWidget {
  const CrudScreen({super.key});
  @override
  State<CrudScreen> createState() => _CrudState();
}

class _CrudState extends State<CrudScreen> {
  // ── colours ──────────────────────────────────────────────────────────────
  static const _green      = Color(0xFF1D9E75);
  static const _greenLight = Color(0xFFE1F5EE);
  static const _greenDark  = Color(0xFF0F6E56);
  static const _border     = Color(0xFFE5E7EB);
  static const _muted      = Color(0xFF6B7280);
  static const _error      = Color(0xFFE24B4A);
  static const _errLight   = Color(0xFFFCEBEB);
  static const _bg         = Color(0xFFF6F8F7);

  // ── state ────────────────────────────────────────────────────────────────
  List<Course> _all      = [];
  List<Course> _filtered = [];
  bool   _loading = true;
  final  _search  = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  // ── data helpers ──────────────────────────────────────────────────────────

  /// READ — loads all courses from SQLite.
  Future<void> _load() async {
    setState(() => _loading = true);
    final courses = await DBService.instance.getCourses();
    if (mounted) {
      setState(() {
        _all      = courses;
        _filtered = courses;
        _loading  = false;
      });
      _onSearch(_search.text);
    }
  }

  /// Filters the list as the user types in the search bar.
  void _onSearch(String q) {
    final query = q.toLowerCase().trim();
    setState(() {
      _filtered = query.isEmpty
          ? _all
          : _all.where((c) =>
      c.title.toLowerCase().contains(query) ||
          c.subtitle.toLowerCase().contains(query)).toList();
    });
  }

  // ── CRUD dialogs ──────────────────────────────────────────────────────────

  /// Shows the Add / Edit form dialog.
  Future<void> _showForm({Course? editing}) async {
    final titleCtrl    = TextEditingController(text: editing?.title    ?? '');
    final subtitleCtrl = TextEditingController(text: editing?.subtitle ?? '');
    final formKey      = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(
            editing == null ? 'Add new module' : 'Edit module',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Title field
            TextFormField(
              controller: titleCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: _fieldDec('Module title', Icons.book_outlined),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 14),
            // Subtitle field
            TextFormField(
              controller: subtitleCtrl,
              decoration: _fieldDec(
                  'Subtitle (e.g. Week 6 · 3 lessons)',
                  Icons.subtitles_outlined),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Subtitle is required' : null,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: _muted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              if (editing == null) {
                // CREATE — insert new course
                final newCourse = Course(
                  id:       'custom_${DateTime.now().millisecondsSinceEpoch}',
                  title:    titleCtrl.text.trim(),
                  subtitle: subtitleCtrl.text.trim(),
                  progress: 0,
                  icon:     Icons.menu_book_outlined,
                );
                await DBService.instance.insertCourse(newCourse);
                _showSnack('Module added ✓');
              } else {
                // UPDATE — save edited fields
                final updated = editing.copyWith(
                  title:    titleCtrl.text.trim(),
                  subtitle: subtitleCtrl.text.trim(),
                );
                await DBService.instance.updateCourse(updated);
                _showSnack('Module updated ✓');
              }

              if (ctx.mounted) Navigator.pop(ctx);
              await _load(); // refresh list
            },
            child: Text(editing == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
    titleCtrl.dispose();
    subtitleCtrl.dispose();
  }

  /// Confirms then deletes a course.
  Future<void> _confirmDelete(Course c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete module?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text(
            'This will permanently delete "${c.title}" from the database.',
            style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: _muted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // DELETE — remove from SQLite
      await DBService.instance.deleteCourse(c.id);
      _showSnack('Module deleted');
      await _load();
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: _green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _green,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Module Manager',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            Text('Week 4 — SQLite CRUD',
                style: TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh',
              onPressed: _load),
        ],
      ),

      // ── FAB — add new module ────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add module'),
        onPressed: () => _showForm(),
      ),

      body: Column(children: [
        // ── CRUD operation legend ───────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: _greenLight,
          child: Row(children: [
            _OpBadge('C', _green),      const SizedBox(width: 4),
            _OpBadge('R', Colors.blue), const SizedBox(width: 4),
            _OpBadge('U', Colors.orange),const SizedBox(width: 4),
            _OpBadge('D', _error),      const SizedBox(width: 10),
            const Text('Tap card to Edit · Long-press to Delete',
                style: TextStyle(fontSize: 11, color: _greenDark)),
          ]),
        ),

        // ── Search bar ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _search,
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: 'Search modules…',
              hintStyle: const TextStyle(fontSize: 13, color: _muted),
              prefixIcon: const Icon(Icons.search, color: _muted, size: 20),
              suffixIcon: _search.text.isNotEmpty
                  ? IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: _muted),
                  onPressed: () { _search.clear(); _onSearch(''); })
                  : null,
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _green, width: 1.5)),
              isDense: true,
            ),
          ),
        ),

        // ── Record count ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
          child: Row(children: [
            Text('${_filtered.length} of ${_all.length} modules',
                style: const TextStyle(fontSize: 12, color: _muted)),
          ]),
        ),

        // ── List ────────────────────────────────────────────────────────
        Expanded(child: _buildList()),
      ]),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(
          color: Color(0xFF1D9E75)));
    }
    if (_filtered.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: _muted),
          const SizedBox(height: 12),
          Text(
              _search.text.isNotEmpty
                  ? 'No results for "${_search.text}"'
                  : 'No modules yet. Tap + to add one.',
              style: const TextStyle(color: _muted, fontSize: 13)),
        ],
      ));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
      itemCount: _filtered.length,
      itemBuilder: (ctx, i) {
        final c    = _filtered[i];
        final done = c.progress >= 1.0;
        return Dismissible(
          // Swipe left to delete
          key: Key(c.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
                color: _errLight,
                borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.delete_outline, color: _error),
          ),
          confirmDismiss: (_) async {
            await _confirmDelete(c);
            return false; // we handle reload ourselves
          },
          child: GestureDetector(
            // Tap → edit
            onTap: () => _showForm(editing: c),
            // Long press → delete confirmation
            onLongPress: () => _confirmDelete(c),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: (!done && c.progress > 0)
                          ? const Color(0xFF1D9E75).withOpacity(0.3)
                          : const Color(0xFFE5E7EB))),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                      color: done
                          ? const Color(0xFF1D9E75)
                          : const Color(0xFFE1F5EE),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(c.icon,
                      color: done ? Colors.white : const Color(0xFF1D9E75),
                      size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.title,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text(c.subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: _muted)),
                  ],
                )),
                // Edit icon
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: _green, size: 18),
                  onPressed: () => _showForm(editing: c),
                  tooltip: 'Edit',
                ),
                // Delete icon
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: _error, size: 18),
                  onPressed: () => _confirmDelete(c),
                  tooltip: 'Delete',
                ),
              ]),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _fieldDec(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _muted, fontSize: 13),
    prefixIcon: Icon(icon, size: 18, color: _muted),
    filled: true, fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _green, width: 1.5)),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _error)),
  );
}

class _OpBadge extends StatelessWidget {
  final String label;
  final Color  color;
  const _OpBadge(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    width: 22, height: 22,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: Center(child: Text(label,
        style: const TextStyle(color: Colors.white,
            fontSize: 10, fontWeight: FontWeight.w700))),
  );
}