import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'db_service.dart';
import 'lesson_model.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});
  @override
  State<LessonScreen> createState() => _LessonState();
}

class _LessonState extends State<LessonScreen> {
  Lesson? _lesson;
  int?  _selected;
  bool  _answered = false;

  static const _green      = Color(0xFF1D9E75);
  static const _greenLight = Color(0xFFE1F5EE);
  static const _greenDark  = Color(0xFF0F6E56);
  static const _border     = Color(0xFFE5E7EB);
  static const _muted      = Color(0xFF6B7280);
  static const _error      = Color(0xFFE24B4A);
  static const _errLight   = Color(0xFFFCEBEB);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_lesson != null) return;
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final id = args?['courseId'] as String? ?? 'week3';
    _loadLesson(id);
  }

  Future<void> _loadLesson(String id) async {
    final l = await DBService.instance.getLesson(id) ?? Lesson.sample();
    if (mounted) setState(() => _lesson = l);
  }

  @override
  Widget build(BuildContext context) {
    if (_lesson == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: _green,
          title: const Text('Loading...',
              style: TextStyle(color: Colors.white)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _green,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_lesson!.title,
                  style: const TextStyle(fontSize: 15, color: Colors.white)),
              Text(_lesson!.subtitle,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.white70)),
            ]),
        actions: [
          IconButton(
              icon: const Icon(Icons.bookmark_outline, color: Colors.white),
              onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.psychology_outlined, color: Colors.white),
              tooltip: 'Ask AI Tutor',
              onPressed: () => Navigator.pushNamed(context, '/ai-tutor',
                  arguments: {'lessonTitle': _lesson!.title})),
        ],
      ),
      body: Column(children: [
        LinearProgressIndicator(
          value: _lesson!.progress, minHeight: 5,
          backgroundColor: _greenLight,
          valueColor: const AlwaysStoppedAnimation<Color>(_greenDark),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF6F8F7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _border)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.timer_outlined,
                        size: 13, color: _muted),
                    const SizedBox(width: 4),
                    Text('${_lesson!.readMinutes} min read',
                        style: const TextStyle(
                            fontSize: 12, color: _muted)),
                  ]),
                ),
                const SizedBox(height: 16),

                MarkdownBody(
                  data: _lesson!.content,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(fontSize: 14, height: 1.7),
                    h2: const TextStyle(fontSize: 16,
                        fontWeight: FontWeight.w600),
                    code: const TextStyle(
                        backgroundColor: Color(0xFFE1F5EE),
                        color: Color(0xFF0F6E56),
                        fontFamily: 'monospace',
                        fontSize: 13),
                    codeblockDecoration: BoxDecoration(
                        color: const Color(0xFFF0FAF6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: _green.withValues(alpha: 0.2))),
                  ),
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: _greenLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _green.withValues(alpha: 0.25))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.psychology_rounded,
                            color: _green, size: 18),
                        SizedBox(width: 6),
                        Text('AI Summary',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _green, fontSize: 13)),
                      ]),
                      const SizedBox(height: 8),
                      Text(_lesson!.aiSummary,
                          style: const TextStyle(fontSize: 13,
                              color: _greenDark, height: 1.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (_lesson!.quiz != null) _buildQuiz(_lesson!.quiz!),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildQuiz(QuizQuestion q) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Quick check',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      Text(q.question,
          style: const TextStyle(fontSize: 14, height: 1.5)),
      const SizedBox(height: 12),

      ...q.options.asMap().entries.map((e) {
        final i = e.key;
        Color bg    = Colors.white;
        Color bc    = _border;
        Color tc    = Colors.black87;
        if (_answered) {
          if (i == q.correctIndex) { bg = _greenLight; bc = _green; tc = _greenDark; }
          else if (i == _selected) { bg = _errLight;   bc = _error; tc = _error; }
        } else if (_selected == i) { bg = _greenLight; bc = _green; }

        return GestureDetector(
          onTap: _answered ? null : () => setState(() => _selected = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
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
                    color: _selected == i ? bc : Colors.transparent),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(e.value,
                  style: TextStyle(fontSize: 13, color: tc))),
            ]),
          ),
        );
      }),
      const SizedBox(height: 12),

      if (!_answered)
        SizedBox(
          width: double.infinity, height: 48,
          child: ElevatedButton(
            onPressed: _selected == null
                ? null : () => setState(() => _answered = true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFB0D9C8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Check answer'),
          ),
        )
      else ...[
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: _selected == q.correctIndex ? _greenLight : _errLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: (_selected == q.correctIndex
                      ? _green : _error).withValues(alpha: 0.3))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                    _selected == q.correctIndex
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    color: _selected == q.correctIndex ? _green : _error,
                    size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(
                    (_selected == q.correctIndex
                        ? '✅ Correct! ' : '❌ Not quite. ') + q.explanation,
                    style: TextStyle(fontSize: 13, height: 1.5,
                        color: _selected == q.correctIndex
                            ? _greenDark : _error))),
              ]),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity, height: 48,
          child: ElevatedButton.icon(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Next lesson'),
          ),
        ),
      ],
    ]);
  }
}
