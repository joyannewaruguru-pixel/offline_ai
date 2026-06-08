import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool   _obscure   = true;
  bool   _loading   = false;
  bool   _isReg     = false;    // toggle login / register
  String? _serverErr;

  static const _green      = Color(0xFF1D9E75);
  static const _greenLight = Color(0xFFE1F5EE);
  static const _greenDark  = Color(0xFF0F6E56);
  static const _border     = Color(0xFFE5E7EB);
  static const _muted      = Color(0xFF6B7280);
  static const _error      = Color(0xFFE24B4A);
  static const _errLight   = Color(0xFFFCEBEB);

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  String? _emailVal(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Invalid email address';
    return null;
  }

  String? _passVal(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Minimum 6 characters';
    return null;
  }

  Future<void> _submit() async {
    setState(() => _serverErr = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthService>();
      final ok = _isReg
          ? await auth.register(_emailCtrl.text.trim(), _passCtrl.text)
          : await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;
      if (ok) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        setState(() => _serverErr = _isReg
            ? 'Registration failed. Try a different email.'
            : 'Incorrect email or password.');
      }
    } catch (_) {
      setState(() => _serverErr = 'Network error. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ───────────────────────────────────────────────────
                Center(child: Column(children: [
                  const Text('LearnAI',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700,
                          color: _green)),
                  const SizedBox(height: 4),
                  Text(_isReg ? 'Create your account' : 'Welcome back',
                      style: const TextStyle(fontSize: 14, color: _muted)),
                ])),
                const SizedBox(height: 40),

                // ── Email ────────────────────────────────────────────────────
                const Text('Email address',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDec(
                      hint: 'student@university.ac.ke',
                      icon: Icons.email_outlined),
                  validator: _emailVal,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 16),

                // ── Password ─────────────────────────────────────────────────
                const Text('Password',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: _inputDec(
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20, color: _muted),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: _passVal,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),

                if (!_isReg)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('Forgot password?',
                          style: TextStyle(fontSize: 13, color: _green)),
                    ),
                  )
                else
                  const SizedBox(height: 8),

                // ── Error banner ─────────────────────────────────────────────
                if (_serverErr != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _errLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _error.withOpacity(0.4)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline,
                          color: _error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_serverErr!,
                          style: const TextStyle(
                              fontSize: 13, color: _error))),
                    ]),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Submit button ────────────────────────────────────────────
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                        : Text(_isReg ? 'Create account' : 'Sign in',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Toggle login / register ───────────────────────────────────
                SizedBox(
                  width: double.infinity, height: 50,
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _isReg = !_isReg;
                      _serverErr = null;
                      _formKey.currentState?.reset();
                    }),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _green,
                      side: const BorderSide(color: _green),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                        _isReg
                            ? 'Already have an account? Sign in'
                            : "Don't have an account? Register",
                        style: const TextStyle(fontSize: 13)),
                  ),
                ),

                // ── Divider ───────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or',
                          style: TextStyle(color: Colors.grey[500],
                              fontSize: 13)),
                    ),
                    const Expanded(child: Divider()),
                  ]),
                ),

                // ── Offline continue ──────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.wifi_off_rounded,
                        color: _green),
                    title: const Text('Continue offline',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 14)),
                    subtitle: const Text('No account needed',
                        style: TextStyle(fontSize: 12, color: _muted)),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 14, color: _muted),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      context.read<AuthService>().continueOffline();
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _muted, fontSize: 14),
      prefixIcon: Icon(icon, size: 20, color: _muted),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _green, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _error)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _error, width: 1.5)),
    );
  }
}