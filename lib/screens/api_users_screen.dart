import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiUser {
  final int id; final String name, email, phone, website, company, city;
  const ApiUser({required this.id, required this.name, required this.email, required this.phone, required this.website, required this.company, required this.city});
  factory ApiUser.fromJson(Map<String, dynamic> j) => ApiUser(id: j['id'] as int, name: j['name'] as String, email: j['email'] as String, phone: j['phone'] as String, website: j['website'] as String, company: (j['company'] as Map)['name'] as String, city: (j['address'] as Map)['city'] as String);
}

class ApiUsersScreen extends StatefulWidget {
  const ApiUsersScreen({super.key});
  @override
  State<ApiUsersScreen> createState() => _ApiUsersState();
}

class _ApiUsersState extends State<ApiUsersScreen> {
  static const _green = Color(0xFF1D9E75);
  List<ApiUser> _all = [], _filtered = [];
  bool _loading = false; String _error = '';
  final _search = TextEditingController();

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final res = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/users'));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        final users = data.map((j) => ApiUser.fromJson(j)).toList();
        setState(() { _all = users; _filtered = users; });
      } else { setState(() => _error = 'Error \${res.statusCode}'); }
    } catch (e) { setState(() => _error = 'Network error'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: _green, title: const Text('API Users')),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: TextField(controller: _search, onChanged: (v) => setState(() => _filtered = _all.where((u) => u.name.toLowerCase().contains(v.toLowerCase())).toList()), decoration: const InputDecoration(hintText: 'Search...'))),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _error.isNotEmpty ? Center(child: Text(_error)) : ListView.builder(itemCount: _filtered.length, itemBuilder: (ctx, i) => ListTile(title: Text(_filtered[i].name), subtitle: Text(_filtered[i].email)))),
      ]),
    );
  }
}
