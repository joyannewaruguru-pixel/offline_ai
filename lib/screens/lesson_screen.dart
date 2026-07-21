import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../auth_service.dart';
import '../db_service.dart';
import '../lesson_model.dart';
import '../models/lesson_model.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});
  @override
  State<LessonScreen> createState() => _LessonState();
}

class _LessonState extends State<LessonScreen> {
  static const _teal      = Color(0xFF00A0A0);
  static const _tealLight = Color(0xFFE0F5F5);
  static const _tealDark  = Color(0xFF006B6B);
  static const _pink      = Color(0xFFFFB6C1);
  static const _pinkDark  = Color(0xFFFF698C);
  static const _muted     = Color(0xFF6B7280);
  static const _error     = Color(0xFFE24B4A);
  static const _errLight  = Color(0xFFFCEBEB);

  Lesson? _lesson;
  int?    _selected;
  bool    _answered   = false;
  bool    _bookmarked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_lesson != null) return;
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final id   = args?['courseId'] as String? ?? 'week3';
    _loadLesson(id);
  }

  Future<void> _loadLesson(String id) async {
    final l     = await DBService.instance.getLesson(id) ?? Lesson.sample();
    final email = context.read<AuthService>().email;
    await DBService.instance.logActivity(email, 'LESSON', 'Opened: ${l.title}');
    if (mounted) setState(() => _lesson = l);
  }

  Future<void> _submitQuiz(QuizQuestion q) async {
    if (_selected == null) return;
    final correct = _selected == q.correctIndex ? 1 : 0;
    final email   = context.read<AuthService>().email;
    await DBService.instance.saveQuizAttempt(_lesson!.id, correct, email);
    await DBService.instance.logActivity(
        email, 'QUIZ',
        '${_lesson!.title}: ${correct == 1 ? "Correct" : "Incorrect"}');
    if (correct == 1) {
      final prog = await DBService.instance.getUserProgress();
      final done = int.tryParse(prog['lessons_done'] ?? '0') ?? 0;
      await DBService.instance.setUserProgress('lessons_done', '${done + 1}');
    }
    setState(() => _answered = true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_lesson == null) {
      return Scaffold(
          appBar: AppBar(
              title: const Text('Loading…'),
              backgroundColor: _teal,
              titleTextStyle: const TextStyle(color: Colors.white, fontSize: 15),
              iconTheme: const IconThemeData(color: Colors.white)),
          body: const Center(
              child: CircularProgressIndicator(color: _teal)));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _teal,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_lesson!.title,
                style: const TextStyle(fontSize: 15, color: Colors.white)),
            Text(_lesson!.subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
              icon: Icon(
                  _bookmarked ? Icons.bookmark : Icons.bookmark_outline,
                  color: Colors.white),
              onPressed: () {
                setState(() => _bookmarked = !_bookmarked);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        _bookmarked ? 'Bookmarked!' : 'Bookmark removed'),
                    backgroundColor: _teal,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))));
              }),
          IconButton(
              icon: const Icon(Icons.psychology_outlined, color: Colors.white),
              tooltip: 'Ask AI Tutor',
              onPressed: () => Navigator.pushNamed(context, '/ai-tutor',
                  arguments: {'lessonTitle': _lesson!.title})),
        ],
      ),
      body: Column(children: [
        LinearProgressIndicator(
            value: _lesson!.progress,
            minHeight: 5,
            backgroundColor: _tealLight,
            valueColor: const AlwaysStoppedAnimation(_tealDark)),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1C1F26)
                            : const Color(0xFFF6F8F7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE5E7EB))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.timer_outlined,
                          size: 13, color: _muted),
                      const SizedBox(width: 4),
                      Text('${_lesson!.readMinutes} min read',
                          style: const TextStyle(fontSize: 12, color: _muted)),
                    ])),
                const SizedBox(height: 16),

                MarkdownBody(
                  data: _lesson!.content,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                        fontSize: 14, height: 1.7,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF1A1A1A)),
                    h2: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF1A1A1A)),
                    h3: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF1A1A1A)),
                    code: const TextStyle(
                        backgroundColor: Color(0xFFE0F5F5),
                        color: Color(0xFF006B6B),
                        fontFamily: 'monospace',
                        fontSize: 13),
                    codeblockDecoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F1117)
                            : const Color(0xFFF0FAFA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: _teal.withOpacity(0.2))),
                    tableHead: const TextStyle(fontWeight: FontWeight.w600),
                    tableBorder: TableBorder.all(
                        color: const Color(0xFFE5E7EB), width: 1),
                    tableColumnWidth: const FlexColumnWidth(),
                  ),
                ),
                const SizedBox(height: 20),

                Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: _tealLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _teal.withOpacity(0.25))),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(children: [
                            Icon(Icons.psychology_rounded,
                                color: _teal, size: 18),
                            SizedBox(width: 6),
                            Text('AI Summary',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _teal, fontSize: 13)),
                          ]),
                          const SizedBox(height: 8),
                          Text(_lesson!.aiSummary,
                              style: const TextStyle(
                                  fontSize: 13, color: _tealDark, height: 1.5)),
                        ])),
                const SizedBox(height: 24),

                if (_lesson!.quiz != null)
                  _buildQuiz(_lesson!.quiz!),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildQuiz(QuizQuestion q) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> optionWidgets = q.options.asMap().entries.map((e) {
      final i = e.key;
      Color bg = isDark ? const Color(0xFF1C1F26) : Colors.white;
      Color bc = const Color(0xFFE5E7EB);
      Color tc = isDark ? Colors.white : Colors.black87;

      if (_answered) {
        if (i == q.correctIndex) {
          bg = _tealLight; bc = _teal; tc = _tealDark;
        } else if (i == _selected) {
          bg = _errLight; bc = _error; tc = _error;
        }
      } else if (_selected == i) {
        bg = _tealLight; bc = _teal;
      }

      return GestureDetector(
          onTap: _answered ? null : () => setState(() => _selected = i),
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: bc)),
              child: Row(children: [
                AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 18, height: 18,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: bc, width: 1.5),
                        color: _selected == i ? bc : Colors.transparent)),
                const SizedBox(width: 12),
                Expanded(child: Text(e.value,
                    style: TextStyle(fontSize: 13, color: tc))),
              ])));
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick check',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Text(q.question,
            style: const TextStyle(fontSize: 14, height: 1.5)),
        const SizedBox(height: 12),

        ...optionWidgets,

        const SizedBox(height: 12),

        if (!_answered)
          SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                  onPressed: _selected == null ? null : () => _submitQuiz(q),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _teal,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _teal.withOpacity(0.4),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Check answer')))
        else ...[
          Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: _selected == q.correctIndex
                      ? _tealLight : _errLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: (_selected == q.correctIndex
                          ? _teal : _error).withOpacity(0.3))),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                        _selected == q.correctIndex
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                        color: _selected == q.correctIndex ? _teal : _error,
                        size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                        (_selected == q.correctIndex
                            ? '✅ Correct! ' : '❌ Not quite. ') + q.explanation,
                        style: TextStyle(
                            fontSize: 13, height: 1.5,
                            color: _selected == q.correctIndex
                                ? _tealDark : _error))),
                  ])),
          const SizedBox(height: 12),
          SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _teal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back to modules'))),
        ],
      ],
    );
  }
}