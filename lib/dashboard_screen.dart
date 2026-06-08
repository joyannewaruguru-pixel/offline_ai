import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course_model.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';
import 'auth_service.dart';
import 'course_model.dart';
import 'db_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardState();
}

class _DashboardState extends State<DashboardScreen> {
  int _tab = 0;
  List<Course> _courses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

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
        const _TutorTab(),
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
              icon: Icon(Icons.psychology_outlined),
              selectedIcon: Icon(Icons.psychology),
              label: 'AI Tutor'),
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
class _HomeTab extends StatelessWidget {
  final List<Course> courses;
  final bool loading;
  const _HomeTab({required this.courses, required this.loading});

  static const _green      = Color(0xFF1D9E75);
  static const _greenLight = Color(0xFFE1F5EE);
  static const _greenDark  = Color(0xFF0F6E56);

  @override
  Widget build(BuildContext context) {
    final w   = MediaQuery.of(context).size.width;
    final pad = w > 600 ? 32.0 : 20.0;

    // FIX 1: compute inProgress outside the widget tree — no 'final' inside [...] spread
    final inProgress = courses.isNotEmpty
        ? courses.firstWhere((c) => c.progress < 1.0, orElse: () => courses.first)
        : null;

    return CustomScrollView(slivers: [
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
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600)),
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

            // Stat cards
            // FIX 2: use a normal list literal, not a 'for' loop inside Row children
            Row(children: _buildStatCards()),
            const SizedBox(height: 24),

            // Continue learning
            const Text('Continue learning',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (inProgress != null)
              _ContinueCard(course: inProgress),
            const SizedBox(height: 24),

            // All modules
            const Text('All modules',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            ...courses.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CourseRow(course: c),
            )),
            const SizedBox(height: 80),
          ]),
        ),
      ),
    ]);
  }

  // Stat cards built as a plain method — avoids 'for' loop inside const context
  static List<Widget> _buildStatCards() {
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
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _green)),
          const SizedBox(height: 2),
          Text(s[1],
              style: const TextStyle(fontSize: 11, color: _greenDark)),
        ]),
      ),
    )).toList();
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
          border: Border.all(color: _green.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                  radius: 20,
                  backgroundColor: _greenLight,
                  child: Icon(course.icon, color: _green, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(course.subtitle,
                      style: const TextStyle(fontSize: 12, color: _muted)),
                ],
              )),
              const Icon(Icons.arrow_forward_ios, size: 14, color: _muted),
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
                  ? _green.withOpacity(0.3)
                  : _border),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: done ? _green : _greenLight,
                borderRadius: BorderRadius.circular(10)),
            child: Icon(course.icon,
                color: done ? Colors.white : _green, size: 22),
          ),
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
            const Icon(Icons.check_circle_rounded, color: _green, size: 22)
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: _greenLight,
                  borderRadius: BorderRadius.circular(20)),
              child: Text(
                  '${(course.progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                      fontSize: 11,
                      color: _green,
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
      title: const Text('All Courses', style: TextStyle(color: Colors.white)),
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

// ── AI Tutor tab ──────────────────────────────────────────────────────────────
class _TutorTab extends StatelessWidget {
  const _TutorTab();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: const Color(0xFF1D9E75),
      title: const Text('AI Tutor', style: TextStyle(color: Colors.white)),
    ),
    body: Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
              color: const Color(0xFFE1F5EE),
              borderRadius: BorderRadius.circular(24)),
          child: const Icon(Icons.psychology_rounded,
              color: Color(0xFF1D9E75), size: 40),
        ),
        const SizedBox(height: 16),
        const Text('Open a lesson and tap',
            style: TextStyle(color: Color(0xFF6B7280))),
        const Text('the AI Tutor button to start',
            style: TextStyle(color: Color(0xFF6B7280))),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/ai-tutor',
              arguments: {'lessonTitle': 'Flutter Widgets'}),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1D9E75),
            foregroundColor: Colors.white,
            minimumSize: const Size(200, 46),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: const Text('Open AI Tutor'),
        ),
      ]),
    ),
  );
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
    const border     = Color(0xFFE5E7EB);
    const error      = Color(0xFFE24B4A);

    // FIX 3: record tuples work in Dart 3 but cause issues with const —
    // use a plain list of maps instead
    final menuItems = [
      {'label': 'Progress & badges',  'icon': Icons.emoji_events_outlined},
      {'label': 'Notifications',      'icon': Icons.notifications_outlined},
      {'label': 'Downloaded content', 'icon': Icons.download_outlined},
      {'label': 'Settings',           'icon': Icons.settings_outlined},
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: green,
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar
          Center(child: Column(children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: greenLight,
              child: Text(
                  auth.userName.isNotEmpty
                      ? auth.userName[0].toUpperCase()
                      : 'S',
                  style: const TextStyle(
                      fontSize: 28,
                      color: green,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 10),
            Text(auth.userName,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            Text(auth.isOffline ? 'Offline mode' : 'Signed in',
                style: const TextStyle(fontSize: 12, color: muted)),
          ])),
          const SizedBox(height: 28),

          // Menu items
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

          // Sign out
          SizedBox(
            width: double.infinity,
            height: 50,
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
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}