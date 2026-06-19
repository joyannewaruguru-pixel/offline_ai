import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_service.dart';
import '../db_service.dart';

/// Represents a single quiz attempt record.
/// Using a dedicated model class improves type safety and readability.
class QuizAttempt {
  final int id;
  final String lessonId;
  final String lessonTitle;
  final int score;
  final DateTime attemptedAt;

  QuizAttempt({
    required this.id,
    required this.lessonId,
    required this.lessonTitle,
    required this.score,
    required this.attemptedAt,
  });

  factory QuizAttempt.fromMap(Map<String, dynamic> map) {
    return QuizAttempt(
      id: map['id'] as int,
      lessonId: map['lesson_id'] as String,
      lessonTitle: map['lesson_title'] as String? ?? map['lesson_id'] as String,
      score: map['score'] as int,
      attemptedAt: DateTime.tryParse(map['attempted_at'] as String) ?? DateTime.now(),
    );
  }

  bool get isPass => score > 0;
}

/// Quiz history screen — reads all past attempts from SQLite.
class QuizHistoryScreen extends StatefulWidget {
  const QuizHistoryScreen({super.key});

  @override
  State<QuizHistoryScreen> createState() => _QuizHistoryState();
}

class _QuizHistoryState extends State<QuizHistoryScreen> {
  // Constants for consistent styling
  static const _green      = Color(0xFF1D9E75);
  static const _greenLight = Color(0xFFE1F5EE);
  static const _greenDark  = Color(0xFF0F6E56);
  static const _muted      = Color(0xFF6B7280);
  static const _error      = Color(0xFFE24B4A);
  static const _errLight   = Color(0xFFFCEBEB);
  static const _bg         = Color(0xFFF6F8F7);

  List<QuizAttempt> _history = [];
  bool _loading = true;

  // Stats derived from history
  int    get _total   => _history.length;
  int    get _correct => _history.where((h) => h.isPass).length;
  double get _avg     => _total == 0 ? 0 : (_correct / _total) * 100;

  @override
  void initState() {
    super.initState();
    // Schedule load after first frame to ensure context is ready for Provider
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      // Get the current user's email from AuthService
      final email = Provider.of<AuthService>(context, listen: false).email;
      final rawData = await DBService.instance.getQuizHistory(email);

      if (mounted) {
        setState(() {
          _history = rawData.map((m) => QuizAttempt.fromMap(m)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading history: $e')),
        );
      }
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all history',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Text(
            'This will permanently delete all your quiz attempt records.',
            style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: _muted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final email = Provider.of<AuthService>(context, listen: false).email;
      await DBService.instance.clearAllQuizHistory(email);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Quiz history cleared'),
            backgroundColor: _green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final y = local.year;
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$d/$m/$y  $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _green,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Quiz History',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
              tooltip: 'Clear all',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : _history.isEmpty
              ? _buildEmpty()
              : Column(children: [
                  _buildStatsSummary(),
                  Expanded(
                    child: RefreshIndicator(
                      color: _green,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: _history.length,
                        itemBuilder: (_, i) => _QuizHistoryCard(
                          attempt: _history[i],
                          formattedDate: _formatDate(_history[i].attemptedAt),
                        ),
                      ),
                    ),
                  ),
                ]),
    );
  }

  Widget _buildStatsSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: _greenLight,
      child: Row(children: [
        _StatBox(value: '$_total',   label: 'Attempts', color: _green),
        const SizedBox(width: 10),
        _StatBox(value: '$_correct', label: 'Correct',  color: _green),
        const SizedBox(width: 10),
        _StatBox(value: '${_avg.toStringAsFixed(0)}%', label: 'Average', color: _green),
      ]),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: _greenLight, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.quiz_outlined, color: _green, size: 36)),
          const SizedBox(height: 16),
          const Text('No quiz attempts yet',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          const Text('Complete a lesson quiz to see history here',
              style: TextStyle(fontSize: 12, color: _muted)),
        ]),
      );
}

/// Private helper widget for history list items.
class _QuizHistoryCard extends StatelessWidget {
  final QuizAttempt attempt;
  final String formattedDate;

  const _QuizHistoryCard({
    required this.attempt,
    required this.formattedDate,
  });

  static const _green      = Color(0xFF1D9E75);
  static const _greenLight = Color(0xFFE1F5EE);
  static const _greenDark  = Color(0xFF0F6E56);
  static const _muted      = Color(0xFF6B7280);
  static const _error      = Color(0xFFE24B4A);
  static const _errLight   = Color(0xFFFCEBEB);

  @override
  Widget build(BuildContext context) {
    final pass = attempt.isPass;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: pass ? _green.withOpacity(0.3) : _error.withOpacity(0.3))),
      child: Row(children: [
        Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: pass ? _greenLight : _errLight,
                borderRadius: BorderRadius.circular(10)),
            child: Icon(
                pass ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: pass ? _green : _error,
                size: 22)),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(attempt.lessonTitle,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
            const SizedBox(height: 2),
            Text(formattedDate, style: const TextStyle(fontSize: 11, color: _muted)),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: pass ? _greenLight : _errLight,
              borderRadius: BorderRadius.circular(20)),
          child: Text(pass ? '✅ Pass' : '❌ Fail',
              style: TextStyle(
                  fontSize: 11,
                  color: pass ? _greenDark : _error,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatBox({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.2))),
          child: Column(children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 10, color: color.withOpacity(0.8))),
          ]),
        ),
      );
}
