import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'gesture_service.dart';
import '../../auth_service.dart';

/// Week 8 — Gesture and keyboard event demo screen.
/// Demonstrates all three touch gestures + keyboard input
/// using the GestureHandler and KeyboardController OOP classes.
class GestureDemoScreen extends StatefulWidget {
  const GestureDemoScreen({super.key});
  @override
  State<GestureDemoScreen> createState() => _GestureDemoState();
}

class _GestureDemoState extends State<GestureDemoScreen> {
  // ── colours ──────────────────────────────────────────────────────────────
  static const _green      = Color(0xFF1D9E75);
  static const _greenLight = Color(0xFFE1F5EE);
  static const _greenDark  = Color(0xFF0F6E56);
  static const _blue       = Color(0xFF1565C0);
  static const _blueLight  = Color(0xFFE3F2FD);
  static const _purple     = Color(0xFF6A1B9A);
  static const _purpleLight= Color(0xFFF3E5F5);
  static const _amber      = Color(0xFFEF9F27);
  static const _amberLight = Color(0xFFFAEEDA);
  static const _error      = Color(0xFFE24B4A);
  static const _errLight   = Color(0xFFFCEBEB);
  static const _muted      = Color(0xFF6B7280);

  // ── OOP service instances ─────────────────────────────────────────────────
  late EventLogger       _logger;
  late GestureHandler    _gestureHandler;
  late KeyboardController _keyboardController;

  // ── screen state ──────────────────────────────────────────────────────────
  final _inputCtrl       = TextEditingController();
  final _formKey         = GlobalKey<FormState>();
  String  _lastMessage   = 'Interact with any element below to see events.';
  Color   _messageBg     = const Color(0xFFE1F5EE);
  Color   _messageColor  = const Color(0xFF0F6E56);
  bool    _swipeRevealed = false;
  int     _swipeCount    = 0;

  @override
  void initState() {
    super.initState();
    final email = context.read<AuthService>().email;
    _logger           = EventLogger();
    _gestureHandler   = GestureHandler(logger: _logger, userEmail: email);
    _keyboardController = KeyboardController(logger: _logger, userEmail: email);
  }

  @override
  void dispose() { _inputCtrl.dispose(); super.dispose(); }

  // ── helpers ───────────────────────────────────────────────────────────────

  void _show(String msg, Color bg, Color text) {
    setState(() {
      _lastMessage  = msg;
      _messageBg    = bg;
      _messageColor = text;
    });
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1117) : const Color(0xFFF6F8F7),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Input & Gesture Demo',
                style: TextStyle(color: Colors.white, fontSize: 15)),
            Text('Week 8 — OOP class-based event handling',
                style: TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
        backgroundColor: _green,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
              icon: const Icon(Icons.history_outlined, color: Colors.white),
              tooltip: 'View event log',
              onPressed: () => _showEventLog(context)),
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Clear log',
              onPressed: () {
                _logger.clear();
                _show('Event log cleared.', _greenLight, _greenDark);
              }),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── OOP class diagram card ────────────────────────────────────
            _SectionCard(
              color: _green,
              lightColor: _greenLight,
              icon: Icons.account_tree_outlined,
              title: 'OOP class structure',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ClassBadge('MobileApp',        _green),
                  _ClassBadge('GestureHandler',   _blue),
                  _ClassBadge('KeyboardController',_purple),
                  _ClassBadge('EventLogger',      _amber),
                  const SizedBox(height: 4),
                  Text(
                      'Each class handles one responsibility — '
                          'tap the elements below to call their methods.',
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : _muted)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Live event message ────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: _messageBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _messageColor.withOpacity(0.3))),
              child: Row(children: [
                Icon(Icons.info_outline, color: _messageColor, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_lastMessage,
                    style: TextStyle(
                        color: _messageColor, fontSize: 13,
                        fontWeight: FontWeight.w500))),
              ]),
            ),
            const SizedBox(height: 16),

            // ── 1. TAP GESTURE ────────────────────────────────────────────
            _SectionLabel('1. Tap gesture', 'GestureHandler.onTap()', _blue),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _GestureCard(
                label: 'Tap me',
                subLabel: 'onTap()',
                color: _blue,
                lightColor: _blueLight,
                icon: Icons.touch_app_outlined,
                onTap: () async {
                  final msg = await _gestureHandler.onTap('Course card');
                  _show(msg, _blueLight, _blue);
                },
              )),
              const SizedBox(width: 10),
              Expanded(child: _GestureCard(
                label: 'Tap AI Tutor',
                subLabel: 'onTap()',
                color: _blue,
                lightColor: _blueLight,
                icon: Icons.psychology_outlined,
                onTap: () async {
                  final msg = await _gestureHandler.onTap('AI Tutor button');
                  _show(msg, _blueLight, _blue);
                },
              )),
            ]),
            const SizedBox(height: 16),

            // ── 2. LONG PRESS ─────────────────────────────────────────────
            _SectionLabel('2. Long press', 'GestureHandler.onLongPress()', _purple),
            const SizedBox(height: 8),
            GestureDetector(
              onLongPress: () async {
                final msg = await _gestureHandler.onLongPress('Module row');
                _show(msg, _purpleLight, _purple);
                _showContextMenu(context);
              },
              child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1F26) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: _purple.withOpacity(0.3))),
                  child: Row(children: [
                    Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                            color: _purpleLight,
                            borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.storage_outlined,
                            color: _purple, size: 22)),
                    const SizedBox(width: 12),
                    const Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Week 4 — Data Management',
                              style: TextStyle(fontWeight: FontWeight.w500)),
                          Text('Hold this row to open context menu',
                              style: TextStyle(fontSize: 12, color: _muted)),
                        ])),
                    const Icon(Icons.more_vert, color: _muted, size: 20),
                  ])),
            ),
            const SizedBox(height: 16),

            // ── 3. SWIPE GESTURE ──────────────────────────────────────────
            _SectionLabel('3. Swipe gesture', 'GestureHandler.onSwipeLeft/Right()', _amber),
            const SizedBox(height: 8),
            // Horizontal drag detector wrapping a card
            GestureDetector(
              onHorizontalDragEnd: (details) async {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < -200) {
                  // swipe left
                  final msg = await _gestureHandler.onSwipeLeft('Lesson card');
                  setState(() { _swipeCount++; _swipeRevealed = true; });
                  _show(msg, _amberLight, _amber);
                } else if (details.primaryVelocity! > 200) {
                  // swipe right
                  final msg = await _gestureHandler.onSwipeRight('Lesson card');
                  setState(() { _swipeCount++; _swipeRevealed = false; });
                  _show(msg, _amberLight, _amber);
                }
              },
              child: Stack(children: [
                // Delete reveal background
                Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: _errLight,
                        borderRadius: BorderRadius.circular(14)),
                    child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.delete_outline, color: _error),
                          SizedBox(width: 8),
                          Text('Swipe left to reveal delete',
                              style: TextStyle(color: _error, fontSize: 13)),
                        ])),
                // Main card (slides on swipe)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  transform: Matrix4.translationValues(
                      _swipeRevealed ? -72 : 0, 0, 0),
                  child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1C1F26) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: _amber.withOpacity(0.3))),
                      child: Row(children: [
                        Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                                color: _amberLight,
                                borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.swipe_outlined,
                                color: _amber, size: 22)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Swipe this card left or right',
                                  style: TextStyle(fontWeight: FontWeight.w500)),
                              Text('Swipes detected: $_swipeCount',
                                  style: const TextStyle(
                                      fontSize: 12, color: _muted)),
                            ])),
                        const Icon(Icons.chevron_left,
                            color: _amber, size: 20),
                      ])),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // ── 4. KEYBOARD INPUT ─────────────────────────────────────────
            _SectionLabel('4. Keyboard input', 'KeyboardController.onKeyInput() + validateInput()', _green),
            const SizedBox(height: 8),
            Form(
              key: _formKey,
              child: Column(children: [
                TextFormField(
                  controller: _inputCtrl,
                  textInputAction: TextInputAction.done,
                  onChanged: (v) async {
                    // Fires on every keystroke — KeyboardController.onKeyInput()
                    await _keyboardController.onKeyInput(v);
                    setState(() {}); // refresh suffix clear button
                  },
                  onFieldSubmitted: (_) async => _submitInput(),
                  decoration: InputDecoration(
                      hintText: 'Type something (min 3 characters)...',
                      prefixIcon: const Icon(
                          Icons.keyboard_outlined, size: 20),
                      suffixIcon: _inputCtrl.text.isNotEmpty
                          ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _inputCtrl.clear();
                            setState(() {});
                          })
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1C1F26)
                          : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: _green.withOpacity(0.4))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: _green.withOpacity(0.3))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: _green, width: 1.5)),
                      errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _error)),
                      isDense: true),
                  validator: (v) =>
                      _keyboardController.validateInput(v ?? ''),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 10),
                SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _submitInput,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Submit (Enter key)'),
                    )),
              ]),
            ),
            const SizedBox(height: 16),

            // ── 5. LIVE EVENT LOG ─────────────────────────────────────────
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SectionLabel(
                      'Live event log',
                      'EventLogger.getHistory()',
                      _green, noSpacing: true),
                  TextButton.icon(
                      onPressed: () => setState(() => _logger.clear()),
                      icon: const Icon(Icons.delete_sweep_outlined,
                          size: 16, color: _muted),
                      label: const Text('Clear',
                          style: TextStyle(fontSize: 12, color: _muted))),
                ]),
            const SizedBox(height: 8),
            ValueListenableBuilder(
                valueListenable: ValueNotifier(_logger.getHistory()),
                builder: (_, __, ___) {
                  final events = _logger.getHistory();
                  if (events.isEmpty) {
                    return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1C1F26)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isDark
                                    ? const Color(0xFF2C2F3A)
                                    : const Color(0xFFE5E7EB))),
                        child: const Center(
                            child: Text('No events yet — interact above',
                                style: TextStyle(color: _muted, fontSize: 13))));
                  }
                  return Container(
                      decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1C1F26)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isDark
                                  ? const Color(0xFF2C2F3A)
                                  : const Color(0xFFE5E7EB))),
                      child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: events.length > 8 ? 8 : events.length,
                          separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: isDark
                                  ? const Color(0xFF2C2F3A)
                                  : const Color(0xFFE5E7EB)),
                          itemBuilder: (_, i) {
                            final e = events[i];
                            return _EventTile(event: e);
                          }));
                }),
            const SizedBox(height: 8),
            Center(
                child: TextButton.icon(
                    onPressed: () => _showEventLog(context),
                    icon: const Icon(Icons.open_in_full,
                        size: 15, color: _green),
                    label: const Text('View full log',
                        style: TextStyle(color: _green, fontSize: 13)))),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  // ── actions ───────────────────────────────────────────────────────────────

  Future<void> _submitInput() async {
    if (!_formKey.currentState!.validate()) return;
    final result = await _keyboardController.onSubmit(_inputCtrl.text);
    _inputCtrl.clear();
    final isError = result.startsWith('Error');
    _show(result,
        isError ? _errLight   : _greenLight,
        isError ? _error      : _green);
    setState(() {});
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => Container(
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2))),
              const Text('Context menu (long press)',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('GestureHandler.onLongPress() fired',
                  style: TextStyle(fontSize: 12, color: _muted)),
              const SizedBox(height: 16),
              ...[
                ('Edit module',   Icons.edit_outlined,   _green),
                ('Delete module', Icons.delete_outlined,  _error),
                ('Share',         Icons.share_outlined,   _blue),
                ('Cancel',        Icons.close,            _muted),
              ].map((item) => ListTile(
                  leading: Icon(item.$2, color: item.$3, size: 20),
                  title: Text(item.$1,
                      style: TextStyle(color: item.$3, fontSize: 14)),
                  onTap: () => Navigator.pop(context))),
            ])));
  }

  void _showEventLog(BuildContext context) {
    final events = _logger.getHistory();
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
            initialChildSize: 0.65,
            maxChildSize: 0.92,
            minChildSize: 0.3,
            builder: (_, ctrl) => Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1C1F26)
                        : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20))),
                child: Column(children: [
                  Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2))),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(children: [
                        const Icon(Icons.list_alt_outlined,
                            color: _green, size: 18),
                        const SizedBox(width: 8),
                        Text('Full event log (${events.length} events)',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                      ])),
                  const SizedBox(height: 8),
                  Expanded(
                      child: events.isEmpty
                          ? const Center(child: Text('No events logged yet'))
                          : ListView.separated(
                          controller: ctrl,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: events.length,
                          separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: Colors.grey[200]),
                          itemBuilder: (_, i) =>
                              _EventTile(event: events[i]))),
                ]))));
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SMALL REUSABLE WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color  color;
  final bool   noSpacing;
  const _SectionLabel(this.title, this.subtitle, this.color,
      {this.noSpacing = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(bottom: noSpacing ? 0 : 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontFamily: 'monospace')),
        ]));
  }
}

class _SectionCard extends StatelessWidget {
  final Color    color;
  final Color    lightColor;
  final IconData icon;
  final String   title;
  final Widget   child;
  const _SectionCard({
    required this.color, required this.lightColor,
    required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1F26) : lightColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: color, fontSize: 13)),
          ]),
          const SizedBox(height: 10),
          child,
        ]));
  }
}

class _ClassBadge extends StatelessWidget {
  final String text;
  final Color  color;
  const _ClassBadge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.code, color: color, size: 12),
          const SizedBox(width: 5),
          Text('class $text',
              style: TextStyle(
                  fontSize: 11, color: color,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500)),
        ]));
  }
}

class _GestureCard extends StatelessWidget {
  final String   label;
  final String   subLabel;
  final Color    color;
  final Color    lightColor;
  final IconData icon;
  final VoidCallback onTap;
  const _GestureCard({
    required this.label,    required this.subLabel,
    required this.color,    required this.lightColor,
    required this.icon,     required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1F26) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.3))),
            child: Column(children: [
              Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                      color: lightColor,
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 24)),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              Text(subLabel,
                  style: TextStyle(
                      fontSize: 10, color: color,
                      fontFamily: 'monospace')),
            ])));
  }
}

class _EventTile extends StatelessWidget {
  final InputEvent event;
  const _EventTile({required this.event});

  Color _colorForType(String type) {
    switch (type) {
      case 'TAP':            return const Color(0xFF1565C0);
      case 'SWIPE_LEFT':
      case 'SWIPE_RIGHT':    return const Color(0xFFEF9F27);
      case 'LONG_PRESS':     return const Color(0xFF6A1B9A);
      case 'KEY_INPUT':      return const Color(0xFF1D9E75);
      case 'FORM_SUBMIT':    return const Color(0xFF1D9E75);
      case 'VALIDATION_FAIL':return const Color(0xFFE24B4A);
      default:               return const Color(0xFF6B7280);
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'TAP':            return Icons.touch_app_outlined;
      case 'SWIPE_LEFT':     return Icons.swipe_left_outlined;
      case 'SWIPE_RIGHT':    return Icons.swipe_right_outlined;
      case 'LONG_PRESS':     return Icons.touch_app;
      case 'KEY_INPUT':      return Icons.keyboard_outlined;
      case 'FORM_SUBMIT':    return Icons.send_rounded;
      case 'VALIDATION_FAIL':return Icons.error_outline;
      default:               return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c  = _colorForType(event.type);
    final t  = event.time;
    final ts = '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}:${t.second.toString().padLeft(2,'0')}';
    return ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
                color: c.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(_iconForType(event.type), color: c, size: 16)),
        title: Text(event.message,
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: c.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(event.type,
                  style: TextStyle(
                      fontSize: 9, color: c,
                      fontWeight: FontWeight.w600))),
          const SizedBox(width: 6),
          Text(ts,
              style: const TextStyle(
                  fontSize: 10, color: Color(0xFF6B7280),
                  fontFamily: 'monospace')),
        ]));
  }
}