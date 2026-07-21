import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'db_service.dart';
import 'services/rag_service.dart';

class AiTutorScreen extends StatefulWidget {
  const AiTutorScreen({super.key});
  @override
  State<AiTutorScreen> createState() => _AiTutorState();
}

class _AiTutorState extends State<AiTutorScreen> {
  static const _green       = Color(0xFF1D9E75);
  static const _greenLight  = Color(0xFFE1F5EE);
  static const _greenDark   = Color(0xFF0F6E56);

  static const _apiKey = 'YOUR_API_KEY_HERE';

  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [];
  bool   _loading     = false;
  bool   _useRag      = false;
  String _lessonTitle = 'Flutter';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    _lessonTitle = args?['lessonTitle'] as String? ?? 'Mobile App Development';
    if (_msgs.isEmpty) {
      _msgs.add(_Msg(ai: true,
          text: 'Hello! I\'m your AI tutor for $_lessonTitle. '
              'What would you like to understand better?'));
    }
  }

  @override
  void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;
    _ctrl.clear();
    final email = context.read<AuthService>().email;

    setState(() { _msgs.add(_Msg(ai: false, text: text)); _loading = true; });
    _scrollDown();

    await DBService.instance.logActivity(email, 'AI_TUTOR', text);

    try {
      String reply;
      if (_useRag) {
        reply = await RagService.instance.askQuestion(text, email: email);
      } else {
        reply = await _callApi(text);
      }
      if (mounted) setState(() => _msgs.add(_Msg(ai: true, text: reply)));
    } catch (_) {
      if (mounted) {
        setState(() => _msgs.add(const _Msg(ai: true,
          text: 'Sorry, I couldn\'t reach the AI right now. '
              'Try enabling AI Notes mode (RAG) to answer from your saved notes offline.')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollDown();
    }
  }

  Future<String> _callApi(String userMsg) async {
    final history = _msgs.map((m) =>
    {'role': m.ai ? 'assistant' : 'user', 'content': m.text}).toList();

    final res = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'x-api-key':         _apiKey,
        'anthropic-version': '2023-06-01',
        'content-type':      'application/json',
      },
      body: jsonEncode({
        'model':      'claude-haiku-4-5-20251001',
        'max_tokens': 600,
        'system':
        'You are a friendly AI tutor for BIT4107 Mobile App Development at a Kenyan university. '
            'Current lesson: $_lessonTitle. '
            'Use Kenya-relevant examples (M-Pesa, eCitizen, Safaricom, Nairobi) where helpful. '
            'Keep answers concise — 2 to 3 short paragraphs. Be encouraging.',
        'messages': [...history, {'role': 'user', 'content': userMsg}],
      }),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      return jsonDecode(res.body)['content'][0]['text'] as String;
    }
    throw Exception('API ${res.statusCode}');
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const suggestions = [
      'Show me a code example',
      'Explain this simply',
      'Give me a Kenya example',
      'What\'s the difference?',
      'Give me a quiz question',
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _green,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(children: [
          CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: const Icon(Icons.psychology_rounded,
                  color: Colors.white, size: 18)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Tutor',
                    style: TextStyle(fontSize: 14, color: Colors.white)),
                Text(_lessonTitle,
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                    overflow: TextOverflow.ellipsis),
              ])),
        ]),
        actions: [
          Tooltip(
              message: _useRag ? 'RAG mode: answers from your notes' : 'Cloud AI mode',
              child: Row(children: [
                const Text('RAG', style: TextStyle(color: Colors.white70, fontSize: 11)),
                Switch(
                    value: _useRag,
                    activeThumbColor: Colors.white,
                    activeTrackColor: Colors.white30,
                    inactiveThumbColor: Colors.white54,
                    inactiveTrackColor: Colors.white24,
                    onChanged: (v) => setState(() => _useRag = v)),
              ])),
          IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: () => setState(() {
                _msgs.clear();
                _msgs.add(_Msg(ai: true, text: 'Chat cleared. What would you like to learn?'));
              })),
        ],
      ),
      body: Column(children: [
        Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            color: _useRag
                ? const Color(0xFFFAEEDA)
                : _greenLight,
            child: Row(children: [
              Icon(
                  _useRag ? Icons.auto_stories_outlined : Icons.cloud_outlined,
                  size: 14,
                  color: _useRag ? const Color(0xFF633806) : _green),
              const SizedBox(width: 6),
              Expanded(child: Text(
                  _useRag
                      ? 'RAG mode — answers from your ingested notes (offline)'
                      : 'Cloud AI mode — Context: $_lessonTitle',
                  style: TextStyle(fontSize: 11,
                      color: _useRag ? const Color(0xFF633806) : _greenDark))),
            ])),

        Expanded(
            child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: _msgs.length + (_loading ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (i == _msgs.length) return _buildTyping();
                  return _buildBubble(_msgs[i], ctx, isDark);
                })),

        if (_msgs.length <= 2)
          SizedBox(
              height: 46,
              child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: suggestions.map((s) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                          label: Text(s, style: const TextStyle(fontSize: 11, color: _greenDark)),
                          backgroundColor: _greenLight,
                          side: BorderSide(color: _green.withValues(alpha: 0.4), width: 0.5),
                          visualDensity: VisualDensity.compact,
                          onPressed: () { _ctrl.text = s; _send(); }))).toList())),

        Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161920) : Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200))),
            child: Row(children: [
              Expanded(
                  child: TextField(
                      controller: _ctrl,
                      onSubmitted: (_) => _send(),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                          hintText: _useRag
                              ? 'Ask about your notes…'
                              : 'Ask anything about the lesson…',
                          isDense: true,
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1C1F26) : const Color(0xFFF6F8F7),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: Colors.grey.shade200)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: Colors.grey.shade200)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: _green))))),
              const SizedBox(width: 8),
              CircleAvatar(
                  backgroundColor: _green,
                  child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      onPressed: _send)),
            ])),
      ]),
    );
  }

  Widget _buildBubble(_Msg m, BuildContext ctx, bool isDark) {
    return Align(
        alignment: m.ai ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(ctx).size.width * 0.78),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: m.ai
                    ? (isDark ? const Color(0xFF1C1F26) : _greenLight)
                    : _green,
                borderRadius: BorderRadius.only(
                    topLeft:     const Radius.circular(14),
                    topRight:    const Radius.circular(14),
                    bottomLeft:  m.ai ? Radius.zero : const Radius.circular(14),
                    bottomRight: m.ai ? const Radius.circular(14) : Radius.zero)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (m.ai) ...[
                const Row(children: [
                  Icon(Icons.psychology_rounded, size: 13, color: _green),
                  SizedBox(width: 4),
                  Text('AI Tutor', style: TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w600, color: _green)),
                ]),
                const SizedBox(height: 5),
              ],
              Text(m.text, style: TextStyle(fontSize: 13, height: 1.5,
                  color: m.ai ? null : Colors.white)),
            ])));
  }

  Widget _buildTyping() => Align(
      alignment: Alignment.centerLeft,
      child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
              color: _greenLight, borderRadius: BorderRadius.circular(14)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(width: 60,
                child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation(_green))),
            SizedBox(width: 8),
            Text('Thinking…', style: TextStyle(fontSize: 12, color: _green)),
          ])));
}

class _Msg {
  final bool ai;
  final String text;
  const _Msg({required this.ai, required this.text});
}
