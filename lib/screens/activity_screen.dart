import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_service.dart';
import '../db_service.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});
  @override
  State<ActivityScreen> createState() => _ActivityState();
}

class _ActivityState extends State<ActivityScreen> {
  static const _green      = Color(0xFF1D9E75);
  static const _muted      = Color(0xFF6B7280);

  List<Map<String,dynamic>> _activities = [];
  bool _loading = true;
  String _filter = 'All';

  static const _actionTypes = [
    'All','LOGIN','LOGOUT','REGISTER','LESSON','QUIZ',
    'CAMERA','FACE_ID','GPS','SENSOR','AI_TUTOR','RAG_QUERY','RAG_INGEST',
  ];

  List<String> get actionTypes => _actionTypes;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final email = context.read<AuthService>().email;
    final rows  = await DBService.instance.getUserActivity(email, limit: 100);
    if (mounted) setState(() { _activities = rows; _loading = false; });
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'LOGIN': case 'REGISTER': return Colors.green;
      case 'LOGOUT':                 return Colors.orange;
      case 'LESSON':                 return _green;
      case 'QUIZ':                   return const Color(0xFF1565C0);
      case 'CAMERA': case 'FACE_ID': return const Color(0xFF6A1B9A);
      case 'GPS':                    return const Color(0xFF00838F);
      case 'SENSOR':                 return const Color(0xFFEF9F27);
      case 'AI_TUTOR':               return _green;
      case 'RAG_QUERY': case 'RAG_INGEST': return const Color(0xFF1565C0);
      default:                       return _muted;
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'LOGIN':      return Icons.login;
      case 'LOGOUT':     return Icons.logout;
      case 'REGISTER':   return Icons.person_add_outlined;
      case 'LESSON':     return Icons.book_outlined;
      case 'QUIZ':       return Icons.quiz_outlined;
      case 'CAMERA':     return Icons.camera_alt_outlined;
      case 'FACE_ID':    return Icons.face_outlined;
      case 'GPS':        return Icons.location_on_outlined;
      case 'SENSOR':     return Icons.sensors_outlined;
      case 'AI_TUTOR':   return Icons.psychology_outlined;
      case 'RAG_QUERY':  return Icons.search_outlined;
      case 'RAG_INGEST': return Icons.upload_file_outlined;
      default:           return Icons.circle_outlined;
    }
  }

  String _fmt(String iso) {
    final dt = DateTime.tryParse(iso) ?? DateTime.now();
    const months = ['','Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month]} ${dt.day}  '
        '${dt.hour.toString().padLeft(2,'0')}:'
        '${dt.minute.toString().padLeft(2,'0')}:'
        '${dt.second.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filter == 'All'
        ? _activities
        : _activities.where((a) => a['action'] == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Activity'),
        backgroundColor: _green,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 16,
            fontWeight: FontWeight.w500),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _load),
          IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
              tooltip: 'Clear all',
              onPressed: () async {
                final email = context.read<AuthService>().email;
                await DBService.instance.logActivity(email, 'CLEAR', 'Activity log cleared');
                await _load();
              }),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : Column(children: [
          SizedBox(
          height: 46,
          child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: actionTypes.map((t) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                      onTap: () => setState(() => _filter = t),
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                              color: _filter == t ? _green : (isDark ? const Color(0xFF1C1F26) : Colors.white),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _filter == t ? _green : const Color(0xFFE5E7EB))),
                          child: Text(t, style: TextStyle(
                              fontSize: 11,
                              color: _filter == t ? Colors.white : _muted,
                              fontWeight: _filter == t ? FontWeight.w600 : FontWeight.normal)))))).toList())),

          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(children: [
                Text('${filtered.length} events',
                    style: const TextStyle(fontSize: 12, color: _muted)),
              ])),

          Expanded(
              child: filtered.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_toggle_off, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    const Text('No activity recorded yet',
                        style: TextStyle(color: _muted)),
                  ]))
                  : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final a      = filtered[i];
                    final action = a['action'] as String;
                    final detail = a['detail'] as String?;
                    final time   = _fmt(a['occurred_at'] as String);
                    final color  = _colorFor(action);
                    return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(children: [
                            Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    shape: BoxShape.circle),
                                child: Icon(_iconFor(action), color: color, size: 18)),
                            if (i < filtered.length - 1)
                              Container(width: 2, height: 30,
                                  color: isDark ? Colors.white12 : Colors.grey.shade200),
                          ]),
                          const SizedBox(width: 12),
                          Expanded(child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                              color: color.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(8)),
                                          child: Text(action, style: TextStyle(
                                              color: color, fontSize: 10,
                                              fontWeight: FontWeight.w600))),
                                      const Spacer(),
                                      Text(time, style: TextStyle(
                                          fontSize: 10, color: Colors.grey[500],
                                          fontFamily: 'monospace')),
                                    ]),
                                    if (detail != null) ...[
                                      const SizedBox(height: 3),
                                      Text(detail, style: const TextStyle(fontSize: 12)),
                                    ],
                                  ]))),
                        ]);
                  })),
          ]),
    );
  }
}
