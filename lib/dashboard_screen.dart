import 'package:flutter/material.dart';
import 'package:offline_ai/services/api_user_screen.dart';
import 'package:provider/provider.dart';
import '../models/course_model.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';
import 'api_users_screen.dart';
import 'auth_service.dart';
import 'course_model.dart';
import 'db_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardState();
}

class _DashboardState extends State<DashboardScreen> {
  int          _tab     = 0;
  List<Course> _courses = [];
  bool         _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final c = await DBService.instance.getCourses();
    if (mounted) setState(() { _courses = c; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: [
        _HomeTab(courses: _courses, loading: _loading),
        _CoursesTab(courses: _courses),
        const _NetworkingTab(),
        const _ProfileTab(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE1F5EE),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.book_outlined),
              selectedIcon: Icon(Icons.book),
              label: 'Courses'),
          NavigationDestination(
              icon: Icon(Icons.cloud_outlined),
              selectedIcon: Icon(Icons.cloud),
              label: 'API'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}

// ── Home tab ──────────────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  final List<Course> courses;
  final bool loading;
  const _HomeTab({required this.courses, required this.loading});
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  static const _green      = Color(0xFF1D9E75);
  static const _greenLight = Color(0xFFE1F5EE);
  static const _greenDark  = Color(0xFF0F6E56);
  static const _muted      = Color(0xFF6B7280);
  static const _bg         = Color(0xFFF6F8F7);

  final _searchCtrl = TextEditingController();
  List<Course> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.courses;
  }

  @override
  void didUpdateWidget(_HomeTab old) {
    super.didUpdateWidget(old);
    // Refresh filtered list when parent passes new courses
    if (widget.courses != old.courses) {
      _onSearch(_searchCtrl.text);
    }
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  void _onSearch(String q) {
    final query = q.toLowerCase().trim();
    setState(() {
      _filtered = query.isEmpty
          ? widget.courses
          : widget.courses.where((c) =>
      c.title.toLowerCase().contains(query) ||
          c.subtitle.toLowerCase().contains(query)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final w   = MediaQuery.of(context).size.width;
    final pad = w > 600 ? 32.0 : 20.0;

    final inProgress = widget.courses.isNotEmpty
        ? widget.courses.firstWhere(
            (c) => c.progress < 1.0,
        orElse: () => widget.courses.first)
        : null;

    return CustomScrollView(slivers: [
      // ── Collapsible app bar ─────────────────────────────────────────────
      SliverAppBar(
        expandedHeight: 130,
        pinned: true,
        backgroundColor: _green,
        flexibleSpace: FlexibleSpaceBar(
          background: Container(
            color: _green,
            padding: EdgeInsets.fromLTRB(pad, 60, pad, 16),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Good morning 👋',
                    style: TextStyle(color: Colors.white,
                        fontSize: 20, fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                Text('BIT4107 · Mobile App Development',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),

      SliverPadding(
        padding: EdgeInsets.all(pad),
        sliver: SliverList(
          delegate: SliverChildListDelegate([

            // ── Stat cards ────────────────────────────────────────────────
            Row(children: _buildStats()),
            const SizedBox(height: 24),

            // ── Quick links ───────────────────────────────────────────────
            Row(children: [
              Expanded(child: _QuickLink(
                icon: Icons.cloud_outlined,
                label: 'Week 5\nAPI Demo',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const ApiUsersScreen())),
              )),
              const SizedBox(width: 10),
              Expanded(child: _QuickLink(
                icon: Icons.psychology_outlined,
                label: 'AI\nTutor',
                onTap: () => Navigator.pushNamed(context, '/ai-tutor',
                    arguments: {'lessonTitle': 'Flutter'}),
              )),
              const SizedBox(width: 10),
              Expanded(child: _QuickLink(
                icon: Icons.quiz_outlined,
                label: 'Latest\nLesson',
                onTap: () => Navigator.pushNamed(context, '/lesson',
                    arguments: {'courseId': 'week3'}),
              )),
            ]),
            const SizedBox(height: 24),

            // ── Continue learning ─────────────────────────────────────────
            const Text('Continue learning',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            if (widget.loading)
              const Center(child: CircularProgressIndicator())
            else if (inProgress != null)
              _ContinueCard(course: inProgress),
            const SizedBox(height: 24),

            // ── Search bar ────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('All modules',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                Text('${_filtered.length} of ${widget.courses.length}',
                    style: const TextStyle(fontSize: 12, color: _muted)),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search modules…',
                hintStyle: const TextStyle(fontSize: 13, color: _muted),
                prefixIcon: const Icon(Icons.search,
                    color: _muted, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                    icon: const Icon(Icons.clear,
                        size: 18, color: _muted),
                    onPressed: () {
                      _searchCtrl.clear();
                      _onSearch('');
                    })
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: _green, width: 1.5)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),

            // ── Filtered module list ──────────────────────────────────────
            if (_filtered.isEmpty && _searchCtrl.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                      'No modules matching "${_searchCtrl.text}"',
                      style: const TextStyle(
                          color: _muted, fontSize: 13)),
                ),
              )
            else
              ..._filtered.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CourseRow(course: c),
              )),

            const SizedBox(height: 80),
          ]),
        ),
      ),
    ]);
  }

  static List<Widget> _buildStats() {
    final data = [
      ['6',    'Lessons'],
      ['82%',  'Quiz avg'],
      ['3 🔥', 'Streak'],
    ];
    return data.map((s) => Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: _greenLight,
            borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text(s[0],
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700,
                  color: _green)),
          const SizedBox(height: 2),
          Text(s[1],
              style: const TextStyle(
                  fontSize: 11, color: _greenDark)),
        ]),
      ),
    )).toList();
  }
}

// ── Quick link button ─────────────────────────────────────────────────────────
class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String   label;
  final VoidCallback onTap;
  const _QuickLink({required this.icon,
    required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Column(children: [
          Icon(icon, color: const Color(0xFF1D9E75), size: 26),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF1D9E75),
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

// ── Continue card ─────────────────────────────────────────────────────────────
class _ContinueCard extends StatelessWidget {
  final Course course;
  const _ContinueCard({required this.course});

  static const _green      = Color(0xFF1D9E75);
  static const _greenLight = Color(0xFFE1F5EE);
  static const _muted      = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/lesson',
          arguments: {'courseId': course.id}),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _green.withOpacity(0.3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(radius: 20, backgroundColor: _greenLight,
                  child: Icon(course.icon, color: _green, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600)),
                  Text(course.subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: _muted)),
                ],
              )),
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: _muted),
            ]),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: course.progress,
                minHeight: 5,
                backgroundColor: _greenLight,
                valueColor: const AlwaysStoppedAnimation<Color>(_green),
              ),
            ),
            const SizedBox(height: 6),
            Text(
                '${(course.progress * 100).toStringAsFixed(0)}% complete',
                style: const TextStyle(fontSize: 11, color: _green)),
          ],
        ),
      ),
    );
  }
}

// ── Course row ────────────────────────────────────────────────────────────────
class _CourseRow extends StatelessWidget {
  final Course course;
  const _CourseRow({required this.course});

  static const _green      = Color(0xFF1D9E75);
  static const _greenLight = Color(0xFFE1F5EE);
  static const _border     = Color(0xFFE5E7EB);
  static const _muted      = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final done = course.progress >= 1.0;
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/lesson',
          arguments: {'courseId': course.id}),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: (!done && course.progress > 0)
                    ? _green.withOpacity(0.3) : _border)),
        child: Row(children: [
          Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: done ? _green : _greenLight,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(course.icon,
                  color: done ? Colors.white : _green, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(course.title,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(course.subtitle,
                  style: const TextStyle(fontSize: 12, color: _muted)),
            ],
          )),
          if (done)
            const Icon(Icons.check_circle_rounded,
                color: _green, size: 22)
          else
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: _greenLight,
                  borderRadius: BorderRadius.circular(20)),
              child: Text(
                  '${(course.progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                      fontSize: 11, color: _green,
                      fontWeight: FontWeight.w600)),
            ),
        ]),
      ),
    );
  }
}

// ── Courses tab ───────────────────────────────────────────────────────────────
class _CoursesTab extends StatelessWidget {
  final List<Course> courses;
  const _CoursesTab({required this.courses});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: const Color(0xFF1D9E75),
      title: const Text('All Courses',
          style: TextStyle(color: Colors.white)),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: courses.map((c) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _CourseRow(course: c),
      )).toList(),
    ),
  );
}

// ── Networking tab — Week 5 API demo ─────────────────────────────────────────
class _NetworkingTab extends StatelessWidget {
  const _NetworkingTab();

  @override
  Widget build(BuildContext context) {
    const green      = Color(0xFF1D9E75);
    const greenLight = Color(0xFFE1F5EE);
    const greenDark  = Color(0xFF0F6E56);
    const muted      = Color(0xFF6B7280);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: green,
        title: const Text('Networking — Week 5',
            style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Concept recap card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: greenLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: green.withOpacity(0.3))),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.lightbulb_outline,
                        color: green, size: 18),
                    SizedBox(width: 6),
                    Text('Week 5 — Networking concepts',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: green, fontSize: 13)),
                  ]),
                  SizedBox(height: 10),
                  _ConceptRow('HTTP GET',    'Retrieve data from server'),
                  _ConceptRow('HTTP POST',   'Send/create data on server'),
                  _ConceptRow('JSON',        'Data exchange format'),
                  _ConceptRow('async/await', 'Non-blocking HTTP calls'),
                  _ConceptRow('REST API',    'Standard web service rules'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('Live demo',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text(
                'Tap below to fetch real user records from a public '
                    'REST API and display them with search functionality.',
                style: TextStyle(fontSize: 13, color: muted, height: 1.5)),
            const SizedBox(height: 16),

            // API info card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.api_outlined, color: green, size: 18),
                    SizedBox(width: 6),
                    Text('JSONPlaceholder API',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ]),
                  const SizedBox(height: 8),
                  const Text('Free public REST API for testing',
                      style: TextStyle(fontSize: 12, color: muted)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF0FAF6),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Text(
                        'GET https://jsonplaceholder\n'
                            '        .typicode.com/users',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: greenDark)),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    _Badge('10 records', green),
                    const SizedBox(width: 6),
                    _Badge('JSON response', green),
                    const SizedBox(width: 6),
                    _Badge('Free', green),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Launch button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const ApiUsersScreen())),
                style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                icon: const Icon(Icons.cloud_download_outlined),
                label: const Text('Launch API Demo',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ConceptRow extends StatelessWidget {
  final String term;
  final String desc;
  const _ConceptRow(this.term, this.desc);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Container(
          width: 90,
          padding: const EdgeInsets.symmetric(
              horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
              color: const Color(0xFF1D9E75),
              borderRadius: BorderRadius.circular(6)),
          child: Text(term,
              style: const TextStyle(
                  fontSize: 10, color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace')),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(desc,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF0F6E56)))),
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color  color;
  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Text(text,
          style: TextStyle(
              fontSize: 10, color: color,
              fontWeight: FontWeight.w500)),
    );
  }
}

// ── Profile tab ───────────────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    const green      = Color(0xFF1D9E75);
    const greenLight = Color(0xFFE1F5EE);
    const muted      = Color(0xFF6B7280);
    const error      = Color(0xFFE24B4A);

    final menuItems = [
      {'label': 'Progress & badges',  'icon': Icons.emoji_events_outlined},
      {'label': 'Notifications',      'icon': Icons.notifications_outlined},
      {'label': 'Downloaded content', 'icon': Icons.download_outlined},
      {'label': 'Settings',           'icon': Icons.settings_outlined},
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: green,
        title: const Text('Profile',
            style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(child: Column(children: [
            CircleAvatar(
                radius: 36, backgroundColor: greenLight,
                child: Text(
                    auth.userName.isNotEmpty
                        ? auth.userName[0].toUpperCase() : 'S',
                    style: const TextStyle(fontSize: 28,
                        color: green, fontWeight: FontWeight.w600))),
            const SizedBox(height: 10),
            Text(auth.userName,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            Text(auth.isOffline ? 'Offline mode' : 'Signed in',
                style: const TextStyle(fontSize: 12, color: muted)),
          ])),
          const SizedBox(height: 28),
          ...menuItems.map((item) => ListTile(
            leading: Icon(item['icon'] as IconData, color: green),
            title: Text(item['label'] as String),
            trailing: const Icon(Icons.arrow_forward_ios,
                size: 14, color: muted),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            onTap: () {},
          )),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                auth.logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
              icon: const Icon(Icons.logout, color: error),
              label: const Text('Sign out',
                  style: TextStyle(color: error)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: error),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ],
      ),
    );
  }
}