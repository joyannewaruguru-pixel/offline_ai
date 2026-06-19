import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_service.dart';
import '../db_service.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';

/// Shows the logged-in user's full activity history from SQLite.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});
  @override
  State<ActivityScreen> createState() => _ActivityState();
}

class _ActivityState extends State<ActivityScreen> {
  List<Map<String, dynamic>> _activities = [];
  bool _loading = true;

  static const _green      = Color(0xFF1D9E75);
  static const _greenLight = Color(0xFFE1F5EE);

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final email = context.read<AuthService>().email;
    final rows  = await DBService.instance.getUserActivity(email);
    if (mounted) setState(() { _activities = rows; _loading = false; });
  }

  Color _actionColor(String action) {
    switch (action) {
      case 'LOGIN':    return Colors.green;
      case 'LOGOUT':   return Colors.orange;
      case 'REGISTER': return Colors.blue;
      case 'QUIZ':     return _green;
      case 'LESSON':   return Colors.purple;
      default:         return Colors.grey;
    }
  }

  IconData _actionIcon(String action) {
    switch (action) {
      case 'LOGIN':    return Icons.login;
      case 'LOGOUT':   return Icons.logout;
      case 'REGISTER': return Icons.person_add_outlined;
      case 'QUIZ':     return Icons.quiz_outlined;
      case 'LESSON':   return Icons.book_outlined;
      default:         return Icons.circle_outlined;
    }
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso) ?? DateTime.now();
    final h  = dt.hour.toString().padLeft(2, '0');
    final m  = dt.minute.toString().padLeft(2, '0');
    const months = ['','Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month]} ${dt.day}, ${dt.year}  $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
          title: const Text('My Activity'),
          actions: [
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _load),
          ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator(
          color: _green))
          : _activities.isEmpty
          ? Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off,
                size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text('No activity recorded yet',
                style: TextStyle(color: Colors.grey)),
          ]))
          : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _activities.length,
          itemBuilder: (ctx, i) {
            final a      = _activities[i];
            final action = a['action'] as String;
            final detail = a['detail'] as String?;
            final time   = _formatDate(a['occurred_at'] as String);
            final color  = _actionColor(action);

            return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline dot + line
                  Column(children: [
                    Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            shape: BoxShape.circle),
                        child: Icon(_actionIcon(action),
                            color: color, size: 18)),
                    if (i < _activities.length - 1)
                      Container(
                          width: 2, height: 32,
                          color: isDark
                              ? Colors.white12
                              : Colors.grey.shade200),
                  ]),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                    color: color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(action,
                                    style: TextStyle(
                                        color: color, fontSize: 10,
                                        fontWeight: FontWeight.w600))),
                            const Spacer(),
                            Text(time,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[500])),
                          ]),
                          if (detail != null) ...[
                            const SizedBox(height: 4),
                            Text(detail,
                                style: const TextStyle(fontSize: 13)),
                          ],
                        ]),
                  )),
                ]);
          }),
    );
  }
}