import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ── Model ─────────────────────────────────────────────────────────────────────
class ApiUser {
  final int    id;
  final String name;
  final String email;
  final String phone;
  final String website;
  final String company;
  final String city;

  const ApiUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.website,
    required this.company,
    required this.city,
  });

  factory ApiUser.fromJson(Map<String, dynamic> j) => ApiUser(
    id:      j['id'] as int,
    name:    j['name']    as String,
    email:   j['email']   as String,
    phone:   j['phone']   as String,
    website: j['website'] as String,
    company: (j['company'] as Map)['name'] as String,
    city:    (j['address'] as Map)['city'] as String,
  );
}

// ── Screen ────────────────────────────────────────────────────────────────────
class ApiUsersScreen extends StatefulWidget {
  const ApiUsersScreen({super.key});
  @override
  State<ApiUsersScreen> createState() => _ApiUsersState();
}

class _ApiUsersState extends State<ApiUsersScreen> {
  // ── colours (no external package) ────────────────────────────────────────
  static const _green      = Color(0xFF1D9E75);
  static const _greenLight = Color(0xFFE1F5EE);
  static const _greenDark  = Color(0xFF0F6E56);
  static const _border     = Color(0xFFE5E7EB);
  static const _muted      = Color(0xFF6B7280);
  static const _bg         = Color(0xFFF6F8F7);
  static const _error      = Color(0xFFE24B4A);
  static const _errLight   = Color(0xFFFCEBEB);

  // ── state ─────────────────────────────────────────────────────────────────
  List<ApiUser> _all      = [];   // full list from API
  List<ApiUser> _filtered = [];   // shown after search
  bool   _loading  = false;
  String _errorMsg = '';
  final  _search   = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // ── HTTP GET ──────────────────────────────────────────────────────────────
  Future<void> _fetchUsers() async {
    setState(() { _loading = true; _errorMsg = ''; });
    try {
      final res = await http
          .get(Uri.parse('https://jsonplaceholder.typicode.com/users'))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body) as List;
        final users = data.map((j) => ApiUser.fromJson(j as Map<String, dynamic>)).toList();
        setState(() { _all = users; _filtered = users; });
      } else {
        setState(() => _errorMsg = 'Server error ${res.statusCode}. Try again.');
      }
    } catch (e) {
      setState(() => _errorMsg = 'Network error. Check your connection and retry.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Search filter ─────────────────────────────────────────────────────────
  void _onSearch(String q) {
    final query = q.toLowerCase().trim();
    setState(() {
      _filtered = query.isEmpty
          ? _all
          : _all.where((u) =>
      u.name.toLowerCase().contains(query)    ||
          u.email.toLowerCase().contains(query)   ||
          u.company.toLowerCase().contains(query) ||
          u.city.toLowerCase().contains(query)).toList();
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────
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
            Text('API Users',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            Text('jsonplaceholder.typicode.com',
                style: TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: _loading ? null : _fetchUsers,
          ),
        ],
      ),
      body: Column(children: [

        // ── HTTP method badge strip ───────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: _greenLight,
          child: Row(children: [
            _MethodBadge('GET',    _green),
            const SizedBox(width: 6),
            const Expanded(
                child: Text('https://jsonplaceholder.typicode.com/users',
                    style: TextStyle(fontSize: 10,
                        color: _greenDark, fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis)),
          ]),
        ),

        // ── Search bar ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _search,
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: 'Search by name, email, company, city…',
              hintStyle: const TextStyle(fontSize: 13, color: _muted),
              prefixIcon: const Icon(Icons.search, color: _muted, size: 20),
              suffixIcon: _search.text.isNotEmpty
                  ? IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: _muted),
                  onPressed: () { _search.clear(); _onSearch(''); })
                  : null,
              filled: true,
              fillColor: Colors.white,
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

        // ── Results count ─────────────────────────────────────────────────
        if (_all.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Row(children: [
              Text('${_filtered.length} of ${_all.length} users',
                  style: const TextStyle(fontSize: 12, color: _muted)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: _greenLight,
                    borderRadius: BorderRadius.circular(20)),
                child: Text('${_all.length} records fetched',
                    style: const TextStyle(
                        fontSize: 10, color: _greenDark)),
              ),
            ]),
          ),

        // ── Body: loading / error / list ──────────────────────────────────
        Expanded(child: _buildBody()),
      ]),
    );
  }

  Widget _buildBody() {
    // Loading spinner
    if (_loading) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF1D9E75)),
            SizedBox(height: 16),
            Text('Fetching users from API…',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
          ],
        ),
      );
    }

    // Error state
    if (_errorMsg.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: _errLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _error.withOpacity(0.3))),
                child: Column(children: [
                  const Icon(Icons.cloud_off_rounded,
                      color: _error, size: 40),
                  const SizedBox(height: 12),
                  Text(_errorMsg,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _error, fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchUsers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty search result
    if (_filtered.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 48, color: Color(0xFF6B7280)),
            const SizedBox(height: 12),
            Text('No users match "${_search.text}"',
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF6B7280))),
          ],
        ),
      );
    }

    // User list
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _filtered.length,
      itemBuilder: (ctx, i) => _UserCard(user: _filtered[i]),
    );
  }
}

// ── User card ─────────────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final ApiUser user;
  const _UserCard({required this.user});

  static const _green      = Color(0xFF1D9E75);
  static const _greenLight = Color(0xFFE1F5EE);
  static const _greenDark  = Color(0xFF0F6E56);
  static const _border     = Color(0xFFE5E7EB);
  static const _muted      = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        shape: const Border(),           // removes default ExpansionTile border
        collapsedShape: const Border(),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: _greenLight,
          child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600,
                  color: _green)),
        ),
        title: Text(user.name,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(user.email,
            style: const TextStyle(fontSize: 12, color: _muted)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: _greenLight,
              borderRadius: BorderRadius.circular(20)),
          child: Text('#${user.id}',
              style: const TextStyle(
                  fontSize: 11, color: _greenDark,
                  fontWeight: FontWeight.w600)),
        ),
        children: [
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 10),
          // Detail rows
          _DetailRow(Icons.phone_outlined,    'Phone',   user.phone),
          _DetailRow(Icons.language_outlined, 'Website', user.website),
          _DetailRow(Icons.business_outlined, 'Company', user.company),
          _DetailRow(Icons.location_on_outlined, 'City', user.city),
          const SizedBox(height: 4),
          // Raw JSON button
          OutlinedButton.icon(
            onPressed: () => _showJson(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: _green,
              side: const BorderSide(color: _green),
              minimumSize: const Size(double.infinity, 38),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.code, size: 16),
            label: const Text('View raw JSON',
                style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showJson(BuildContext context) {
    // Pretty-print the user as JSON for the student to see
    const encoder = JsonEncoder.withIndent('  ');
    final pretty = encoder.convert({
      'id':      user.id,
      'name':    user.name,
      'email':   user.email,
      'phone':   user.phone,
      'website': user.website,
      'company': {'name': user.company},
      'address': {'city': user.city},
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(children: [
            // Handle
            Container(
                width: 40, height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                const Icon(Icons.code, color: Color(0xFF1D9E75), size: 18),
                const SizedBox(width: 8),
                Text('JSON — ${user.name}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ]),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF0FAF6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF1D9E75).withOpacity(0.2))),
                  child: Text(pretty,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFF0F6E56),
                          height: 1.6)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  const _DetailRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 15, color: const Color(0xFF1D9E75)),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500,
                color: Color(0xFF1D9E75))),
        Expanded(child: Text(value,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF6B7280)))),
      ]),
    );
  }
}

// ── HTTP method badge ─────────────────────────────────────────────────────────
class _MethodBadge extends StatelessWidget {
  final String label;
  final Color  color;
  const _MethodBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5)),
    );
  }
}