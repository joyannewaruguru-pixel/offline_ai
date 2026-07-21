import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_service.dart';
import '../db_service.dart';
import '../services/rag_service.dart';

class RagScreen extends StatefulWidget {
  const RagScreen({super.key});
  @override
  State<RagScreen> createState() => _RagState();
}

class _RagState extends State<RagScreen> with SingleTickerProviderStateMixin {
  static const _green = Color(0xFF1D9E75);
  static const _greenLight = Color(0xFFE1F5EE);
  static const _error = Color(0xFFE24B4A);
  static const _errLight = Color(0xFFFCEBEB);

  late TabController _tabs;
  final _textCtrl = TextEditingController();
  final _docNameCtrl = TextEditingController();
  final _queryCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<Map<String,dynamic>> _docs = [];
  final List<_ChatMsg> _messages = [];
  String? _selectedDoc;
  bool _ingesting = false;
  bool _querying = false;
  String _ingestStatus = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadDocs();
  }

  @override
  void dispose() {
    _tabs.dispose(); _textCtrl.dispose(); _docNameCtrl.dispose(); _queryCtrl.dispose(); _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDocs() async {
    final email = context.read<AuthService>().email;
    final docs = await DBService.instance.getRagDocuments(email);
    if (mounted) setState(() => _docs = docs);
  }

  Future<void> _ingestText() async {
    final text = _textCtrl.text.trim();
    final name = _docNameCtrl.text.trim();
    if (text.isEmpty || name.isEmpty) { setState(() => _ingestStatus = 'Fill all fields.'); return; }
    setState(() { _ingesting = true; _ingestStatus = 'Processing...'; });
    try {
      final email = context.read<AuthService>().email;
      final docId = await RagService.instance.ingestText(name, text, email);
      await _loadDocs();
      _textCtrl.clear(); _docNameCtrl.clear();
      setState(() { _ingesting = false; _ingestStatus = 'Success.'; _selectedDoc = docId; });
    } catch (e) {
      setState(() { _ingesting = false; _ingestStatus = 'Error: $e'; });
    }
  }

  Future<void> _askQuestion() async {
    final query = _queryCtrl.text.trim();
    if (query.isEmpty || _querying) return;
    _queryCtrl.clear();
    setState(() { _messages.add(_ChatMsg(role: 'user', text: query)); _querying = true; });
    try {
      final email = context.read<AuthService>().email;
      final answer = await RagService.instance.askQuestion(query, docId: _selectedDoc, email: email);
      setState(() { _messages.add(_ChatMsg(role: 'ai', text: answer)); _querying = false; });
    } catch (e) {
      setState(() { _messages.add(_ChatMsg(role: 'ai', text: 'Error: $e')); _querying = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: _green, title: const Text('AI Notes (RAG)'),
        bottom: TabBar(controller: _tabs, tabs: const [Tab(text: 'How it works'), Tab(text: 'Add'), Tab(text: 'Ask')]),
      ),
      body: TabBarView(controller: _tabs, children: [
        const Center(child: Text('RAG Info')),
        _addNotesTab(),
        _askAiTab(),
      ]),
    );
  }

  Widget _addNotesTab() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      TextField(controller: _docNameCtrl, decoration: const InputDecoration(hintText: 'Name')),
      const SizedBox(height: 10),
      TextField(controller: _textCtrl, maxLines: 5, decoration: const InputDecoration(hintText: 'Content')),
      const SizedBox(height: 10),
      ElevatedButton(onPressed: _ingesting ? null : _ingestText, child: Text(_ingesting ? 'Processing...' : 'Ingest')),
      Text(_ingestStatus),
    ]);
  }

  Widget _askAiTab() {
    return Column(children: [
      Expanded(child: ListView.builder(itemCount: _messages.length, itemBuilder: (ctx, i) => ListTile(title: Text(_messages[i].text), subtitle: Text(_messages[i].role)))),
      Padding(padding: const EdgeInsets.all(8), child: TextField(controller: _queryCtrl, onSubmitted: (_) => _askQuestion())),
    ]);
  }
}

class _ChatMsg {
  final String role, text;
  const _ChatMsg({required this.role, required this.text});
}
