import 'package:flutter/material.dart';
import 'package:offline_ai/screens/activity_screen.dart';
import 'package:offline_ai/screens/api_users_screen.dart';
import 'package:offline_ai/screens/crud_screen.dart';
import 'package:offline_ai/screens/device_features_screen.dart';
import 'package:offline_ai/screens/gesture_demo_screen.dart';
import 'package:offline_ai/screens/library_screen.dart';
import 'package:offline_ai/screens/rag_screen.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/time_service.dart';
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
  void initState() { super.initState(); _loadCourses(); }

  Future<void> _loadCourses() async {
    final c = await DBService.instance.getCourses();
    if (mounted) setState(() { _courses = c; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: [
        _HomeTab(courses: _courses, loading: _loading),
        _CoursesTab(courses: _courses),
        const _NetworkTab(),
        const _ProfileTab(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.book_outlined), selectedIcon: Icon(Icons.book), label: 'Courses'),
          NavigationDestination(
              icon: Icon(Icons.cloud_outlined), selectedIcon: Icon(Icons.cloud), label: 'API'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  final List<Course> courses;
  final bool loading;
  const _HomeTab({required this.courses, required this.loading});
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  static const _green      = Color(0xFF1D9E75);
  static const _muted      = Color(0xFF6B7280);

  GreetingInfo? _greeting;
  bool _greetLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();
  List<Course> _filtered = [];
  String _streak = '3', _lessonsDone = '6', _quizAvg = '82%';

  @override
  void initState() {
    super.initState();
    _filtered = widget.courses;
    _loadGreeting();
    _loadStats();
  }

  @override
  void didUpdateWidget(_HomeTab old) {
    super.didUpdateWidget(old);
    if (widget.courses != old.courses) {
      _filtered = widget.courses;
      _onSearch(_searchCtrl.text);
    }
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _loadGreeting() async {
    final info = await TimeService.instance.getGreeting();
    if (mounted) setState(() { _greeting = info; _greetLoading = false; });
    await Future.delayed(const Duration(minutes: 1));
    if (mounted) _loadGreeting();
  }

  Future<void> _loadStats() async {
    final prog = await DBService.instance.getUserProgress();
    if (mounted) {
      setState(() {
        _streak      = prog['streak']       ?? '3';
        _lessonsDone = prog['lessons_done'] ?? '6';
        _quizAvg     = '${prog['quiz_avg'] ?? '82'}%';
      });
    }
  }

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
    final w    = MediaQuery.of(context).size.width;
    final pad  = w > 600 ? 32.0 : 20.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgTop    = _greeting?.bgTop    ?? _green;
    final bgBottom = _greeting?.bgBottom ?? const Color(0xFF15785A);

    final inProgress = widget.courses.isNotEmpty
        ? widget.courses.firstWhere((c) => c.progress < 1.0,
        orElse: () => widget.courses.first)
        : null;

    return CustomScrollView(slivers: [
      SliverAppBar(
        expandedHeight: 155, pinned: true, backgroundColor: bgTop,
        actions: [
          Consumer<ThemeService>(
              builder: (_, ts, __) => IconButton(
                  tooltip: ts.isDark ? 'Light mode' : 'Dark mode',
                  icon: Icon(ts.isDark ? Icons.light_mode : Icons.dark_mode,
                      color: Colors.white),
                  onPressed: ts.toggle)),
          Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _greetLoading
                  ? const Padding(padding: EdgeInsets.all(14),
                  child: SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                  : Tooltip(message: 'Time from WorldTimeAPI',
                  child: Icon(_greeting!.greetIcon, color: Colors.white70, size: 22))),
        ],
        flexibleSpace: FlexibleSpaceBar(
          background: AnimatedContainer(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [bgTop, bgBottom])),
            padding: EdgeInsets.fromLTRB(pad, 62, pad, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end, children: [
                  _greetLoading ? const _Shimmer(width: 200, height: 22)
                      : Text('${_greeting!.greeting} ${_greeting!.emoji}',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  _LiveClock(color: Colors.white60),
                  const SizedBox(height: 2),
                  if (!_greetLoading)
                    Text(_greeting!.subtext,
                        style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ]),
          ),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.all(pad),
        sliver: SliverList(delegate: SliverChildListDelegate([

          Row(children: [
            _StatCard(value: _lessonsDone, label: 'Lessons', isDark: isDark),
            const SizedBox(width: 8),
            _StatCard(value: _quizAvg,     label: 'Quiz avg', isDark: isDark),
            const SizedBox(width: 8),
            _StatCard(value: '$_streak 🔥', label: 'Streak',  isDark: isDark),
          ]),
          const SizedBox(height: 16),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            childAspectRatio: 1.0,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              _QuickLink(icon: Icons.library_books_outlined, label: 'Library',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LibraryScreen()))),
              _QuickLink(icon: Icons.psychology_outlined,    label: 'AI Tutor',
                  onTap: () => Navigator.pushNamed(context, '/ai-tutor',
                      arguments: {'lessonTitle': 'Flutter'})),
              _QuickLink(icon: Icons.auto_stories_outlined,  label: 'AI Notes',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RagScreen()))),
              _QuickLink(icon: Icons.manage_accounts_outlined, label: 'Manage',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CrudScreen()))),
              _QuickLink(icon: Icons.camera_alt_outlined,    label: 'Camera',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const DeviceFeaturesScreen()))),
              _QuickLink(icon: Icons.touch_app_outlined,     label: 'Gestures',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const GestureDemoScreen()))),
              _QuickLink(icon: Icons.cloud_outlined,         label: 'API Demo',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ApiUsersScreen()))),
              _QuickLink(icon: Icons.history_outlined,       label: 'Activity',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ActivityScreen()))),
            ],
          ),
          const SizedBox(height: 20),

          const Text('Continue learning',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          if (widget.loading)
            const Center(child: CircularProgressIndicator(color: _green))
          else if (inProgress != null)
            _ContinueCard(course: inProgress),
          const SizedBox(height: 20),

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('All modules',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            Text('${_filtered.length}/${widget.courses.length}',
                style: const TextStyle(fontSize: 12, color: _muted)),
          ]),
          const SizedBox(height: 10),
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearch,
            decoration: InputDecoration(
                hintText: 'Search modules…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () { _searchCtrl.clear(); _onSearch(''); })
                    : null,
                isDense: true,
                filled: true,
                fillColor: isDark ? const Color(0xFF1C1F26) : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _green, width: 1.5))),
          ),
          const SizedBox(height: 10),

          ..._filtered.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CourseRow(course: c))),
          const SizedBox(height: 80),
        ])),
      ),
    ]);
  }
}

class _LiveClock extends StatefulWidget {
  final Color color;
  const _LiveClock({required this.color});
  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  DateTime _now = DateTime.now();
  @override
  void initState() { super.initState(); _tick(); }
  Future<void> _tick() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) { setState(() => _now = DateTime.now()); _tick(); }
  }
  String _p(int n) => n.toString().padLeft(2, '0');
  @override
  Widget build(BuildContext context) {
    const days   = ['','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    const months = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return Text(
        '${_p(_now.hour)}:${_p(_now.minute)}:${_p(_now.second)}'
            '  ·  ${days[_now.weekday]} ${_now.day} ${months[_now.month]} ${_now.year}',
        style: TextStyle(color: widget.color, fontSize: 12,
            fontFeatures: const [FontFeature.tabularFigures()]));
  }
}

class _Shimmer extends StatefulWidget {
  final double width, height;
  const _Shimmer({required this.width, required this.height});
  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double>   _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _a = Tween<double>(begin: 0.2, end: 0.6).animate(_c);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _a,
      builder: (_, __) => Container(width: widget.width, height: widget.height,
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: _a.value),
              borderRadius: BorderRadius.circular(6))));
}

class _StatCard extends StatelessWidget {
  final String value, label;
  final bool isDark;
  const _StatCard({required this.value, required this.label, required this.isDark});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1D9E75).withValues(alpha: 0.15)
              : const Color(0xFFE1F5EE),
          borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700,
            color: Color(0xFF1D9E75))),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF0F6E56))),
      ])));
}

class _QuickLink extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _QuickLink({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
        onTap: onTap,
        child: Container(
            decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1F26) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark ? const Color(0xFF2C2F3A) : const Color(0xFFE5E7EB))),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: const Color(0xFF1D9E75), size: 24),
              const SizedBox(height: 5),
              Text(label, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF1D9E75),
                      fontWeight: FontWeight.w500)),
            ])));
  }
}

class _ContinueCard extends StatelessWidget {
  final Course course;
  const _ContinueCard({required this.course});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
        onTap: () => Navigator.pushNamed(context, '/lesson',
            arguments: {'courseId': course.id}),
        borderRadius: BorderRadius.circular(16),
        child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1F26) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1D9E75).withValues(alpha: 0.3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(radius: 20,
                    backgroundColor: const Color(0xFFE1F5EE),
                    child: Icon(course.icon, color: const Color(0xFF1D9E75), size: 22)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(course.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(course.subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ])),
                const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF6B7280)),
              ]),
              const SizedBox(height: 12),
              ClipRRect(borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: course.progress, minHeight: 5,
                      backgroundColor: const Color(0xFFE1F5EE),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF1D9E75)))),
              const SizedBox(height: 6),
              Text('${(course.progress * 100).toStringAsFixed(0)}% complete',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF1D9E75))),
            ])));
  }
}

class _CourseRow extends StatelessWidget {
  final Course course;
  const _CourseRow({required this.course});
  @override
  Widget build(BuildContext context) {
    final done  = course.progress >= 1.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
        onTap: () => Navigator.pushNamed(context, '/lesson',
            arguments: {'courseId': course.id}),
        borderRadius: BorderRadius.circular(14),
        child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1F26) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: (!done && course.progress > 0)
                        ? const Color(0xFF1D9E75).withValues(alpha: 0.3)
                        : isDark ? const Color(0xFF2C2F3A) : const Color(0xFFE5E7EB))),
            child: Row(children: [
              Container(width: 44, height: 44,
                  decoration: BoxDecoration(
                      color: done ? const Color(0xFF1D9E75) : const Color(0xFFE1F5EE),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(course.icon,
                      color: done ? Colors.white : const Color(0xFF1D9E75), size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(course.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(course.subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ])),
              if (done)
                const Icon(Icons.check_circle_rounded, color: Color(0xFF1D9E75), size: 22)
              else
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: const Color(0xFFE1F5EE),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('${(course.progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF1D9E75),
                            fontWeight: FontWeight.w600))),
            ])));
  }
}

class _CoursesTab extends StatelessWidget {
  final List<Course> courses;
  const _CoursesTab({required this.courses});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('All Courses')),
      body: ListView(
          padding: const EdgeInsets.all(20),
          children: courses.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CourseRow(course: c))).toList()));
}

class _NetworkTab extends StatelessWidget {
  const _NetworkTab();
  @override
  Widget build(BuildContext context) {
    const green      = Color(0xFF1D9E75);
    const greenLight = Color(0xFFE1F5EE);
    const greenDark  = Color(0xFF0F6E56);
    final timeRows = [
      ['05:00–11:59', 'Good morning 🌅',   green],
      ['12:00–16:59', 'Good afternoon ☀️', Color(0xFF1565C0)],
      ['17:00–20:59', 'Good evening 🌇',   Color(0xFF6A1B9A)],
      ['21:00–04:59', 'Good night 🌙',     Color(0xFF1A237E)],
    ];
    return Scaffold(
        appBar: AppBar(title: const Text('Networking — Week 5')),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: greenLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: green.withValues(alpha: 0.3))),
                  child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.access_time, color: green, size: 18),
                      SizedBox(width: 6),
                      Text('Time API — WorldTimeAPI',
                          style: TextStyle(fontWeight: FontWeight.w600, color: green, fontSize: 13)),
                    ]),
                    SizedBox(height: 8),
                    Text('The dashboard greeting uses a live GET request to WorldTimeAPI '
                        'for Africa/Nairobi timezone. Greeting text and header gradient '
                        'change based on time of day.',
                        style: TextStyle(fontSize: 12, color: greenDark, height: 1.5)),
                  ])),
              const SizedBox(height: 16),
              const Text('Greeting schedule',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              ...timeRows.map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: (r[2] as Color).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: (r[2] as Color).withValues(alpha: 0.25))),
                  child: Row(children: [
                    const Icon(Icons.schedule, size: 16),
                    const SizedBox(width: 8),
                    Text(r[0] as String, style: TextStyle(fontFamily: 'monospace',
                        fontSize: 11, color: r[2] as Color, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text(r[1] as String, style: TextStyle(fontSize: 12,
                        color: r[2] as Color, fontWeight: FontWeight.w500)),
                  ]))),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, height: 50,
                  child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ApiUsersScreen())),
                      icon: const Icon(Icons.people_outline),
                      label: const Text('Open Users API Demo'))),
            ])));
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();
  @override
  Widget build(BuildContext context) {
    final auth      = context.read<AuthService>();
    final themeServ = context.watch<ThemeService>();
    const green      = Color(0xFF1D9E75);
    const greenLight = Color(0xFFE1F5EE);
    const muted      = Color(0xFF6B7280);
    const error      = Color(0xFFE24B4A);

    final menuItems = [
      {'label':'Library',          'icon':Icons.library_books_outlined, 'route':'/library'},
      {'label':'AI Notes (RAG)',   'icon':Icons.auto_stories_outlined,  'route':'/rag'},
      {'label':'Data Manager',     'icon':Icons.manage_accounts_outlined,'route':'/crud'},
      {'label':'My Activity',      'icon':Icons.history_outlined,        'route':'/activity'},
      {'label':'Device Features',  'icon':Icons.sensors_outlined,        'route':'/device-features'},
      {'label':'Gesture Demo',     'icon':Icons.touch_app_outlined,      'route':'/gesture-demo'},
      {'label':'Settings',         'icon':Icons.settings_outlined,       'route':''},
    ];

    return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(child: Column(children: [
                CircleAvatar(radius: 38, backgroundColor: greenLight,
                    child: Text(
                        auth.userName.isNotEmpty ? auth.userName[0].toUpperCase() : 'S',
                        style: const TextStyle(fontSize: 30, color: green,
                            fontWeight: FontWeight.w700))),
                const SizedBox(height: 10),
                Text(auth.userName, style: const TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w600)),
                Text(auth.email, style: const TextStyle(fontSize: 12, color: muted)),
                Text(auth.isOffline ? 'Offline mode' : 'Signed in',
                    style: const TextStyle(fontSize: 11, color: muted)),
              ])),
              const SizedBox(height: 24),

              Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor)),
                  child: Row(children: [
                    Icon(themeServ.isDark ? Icons.dark_mode : Icons.light_mode, color: green),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Dark mode',
                        style: TextStyle(fontWeight: FontWeight.w500))),
                    Switch(value: themeServ.isDark, onChanged: (_) => themeServ.toggle(),
                        activeThumbColor: green),
                  ])),

              ...menuItems.map((item) => ListTile(
                  leading: Icon(item['icon'] as IconData, color: green),
                  title: Text(item['label'] as String),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: muted),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onTap: () {
                    final route = item['route'] as String;
                    if (route.isNotEmpty) Navigator.pushNamed(context, route);
                  })),
              const SizedBox(height: 20),

              SizedBox(width: double.infinity, height: 50,
                  child: OutlinedButton.icon(
                      onPressed: () {
                        auth.logout();
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      icon: const Icon(Icons.logout, color: error),
                      label: const Text('Sign out', style: TextStyle(color: error)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: error),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))))),
            ]));
  }
}
