import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingState();
}

class _OnboardingState extends State<OnboardingScreen> {
  int    _level       = -1;
  double _dlProgress  = 0;
  bool   _downloading = false;
  bool   _done        = false;

  static const _levels = [
    {'icon': Icons.school_outlined,          'title': 'Beginner',      'desc': 'Start from the basics'},
    {'icon': Icons.code_outlined,            'title': 'Intermediate',  'desc': 'I know some programming'},
    {'icon': Icons.rocket_launch_outlined,   'title': 'Advanced',      'desc': 'Final year or professional'},
  ];

  Future<void> _download() async {
    setState(() => _downloading = true);
    for (int i = 1; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 25));
      if (mounted) setState(() => _dlProgress = i / 100);
    }
    if (mounted) setState(() { _downloading = false; _done = true; });
  }

  Future<void> _proceed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    await prefs.setInt('user_level', _level);
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    const green      = Color(0xFF1D9E75);
    const greenLight = Color(0xFFE1F5EE);
    const greenDark  = Color(0xFF0F6E56);
    const border     = Color(0xFFE5E7EB);
    const bg         = Color(0xFFF6F8F7);
    const muted      = Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Logo ─────────────────────────────────────────────────────────
            Center(child: Column(children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                    color: green, borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.psychology_rounded,
                    color: Colors.white, size: 38),
              ),
              const SizedBox(height: 14),
              const Text('LearnAI',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
                      color: green)),
              const SizedBox(height: 4),
              const Text('Offline AI Learning Platform',
                  style: TextStyle(fontSize: 13, color: muted)),
            ])),
            const SizedBox(height: 36),

            // ── Level picker ──────────────────────────────────────────────────
            const Text('Choose your level',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            ...List.generate(_levels.length, (i) {
              final sel  = _level == i;
              final item = _levels[i];
              return GestureDetector(
                onTap: () => setState(() => _level = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: sel ? greenLight : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: sel ? green : border,
                        width: sel ? 1.5 : 1),
                  ),
                  child: Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                          color: sel ? green : bg,
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(item['icon'] as IconData,
                          color: sel ? Colors.white : muted, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['title'] as String,
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14,
                                color: sel ? greenDark : Colors.black87)),
                        const SizedBox(height: 2),
                        Text(item['desc'] as String,
                            style: const TextStyle(fontSize: 12, color: muted)),
                      ],
                    )),
                    if (sel)
                      const Icon(Icons.check_circle_rounded, color: green),
                  ]),
                ),
              );
            }),

            // ── Download section ──────────────────────────────────────────────
            if (_level >= 0) ...[
              const SizedBox(height: 24),
              const Text('Download content pack',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: greenLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: green.withOpacity(0.3)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.folder_zip_outlined, color: green),
                      const SizedBox(width: 8),
                      const Expanded(
                          child: Text('BIT4107 Mobile Dev Pack — 120 MB',
                              style: TextStyle(fontSize: 13,
                                  fontWeight: FontWeight.w500, color: greenDark))),
                      if (_done)
                        const Icon(Icons.check_circle_rounded,
                            color: green, size: 20),
                    ]),
                    if (_downloading || _done) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _dlProgress, minHeight: 6,
                          backgroundColor: green.withOpacity(0.15),
                          valueColor:
                          const AlwaysStoppedAnimation<Color>(green),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                          _done
                              ? 'Download complete!'
                              : '${(_dlProgress * 120).toStringAsFixed(0)} MB / 120 MB',
                          style: TextStyle(
                              fontSize: 12,
                              color: _done ? green : greenDark)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (!_done)
                ElevatedButton.icon(
                  onPressed: _downloading ? null : _download,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: _downloading
                      ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download_rounded),
                  label: Text(_downloading
                      ? 'Downloading...' : 'Download for offline use'),
                ),
              if (_done) ...[
                ElevatedButton(
                  onPressed: _proceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green, foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Get started →'),
                ),
                const SizedBox(height: 10),
              ],
            ],

            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Skip for now',
                    style: TextStyle(color: muted)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}