import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool    _obscure  = true;
  bool    _loading  = false;
  bool    _isReg    = false;
  String? _serverErr;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _serverErr = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthService>();
      final err = _isReg
          ? await auth.register(
          _nameCtrl.text.trim(),
          _emailCtrl.text.trim(),
          _passCtrl.text)
          : await auth.login(
          _emailCtrl.text.trim(),
          _passCtrl.text);
      if (!mounted) return;
      if (err == null) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        setState(() => _serverErr = err);
      }
    } catch (_) {
      setState(() => _serverErr = 'An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const green  = Color(0xFF1D9E75);
    final muted  = isDark ? Colors.white38 : const Color(0xFF6B7280);
    const error  = Color(0xFFE24B4A);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Column(children: [
                    Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                            color: green, borderRadius: BorderRadius.circular(18)),
                        child: const Icon(Icons.psychology_rounded,
                            color: Colors.white, size: 34)),
                    const SizedBox(height: 14),
                    const Text('LearnAI', style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w700,
                        color: Color(0xFF1D9E75))),
                    const SizedBox(height: 4),
                    Text(_isReg ? 'Create your account' : 'Welcome back',
                        style: TextStyle(fontSize: 13, color: muted)),
                  ])),
                  const SizedBox(height: 36),

                  if (_isReg) ...[
                    _label('Full name'),
                    TextFormField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: _dec('e.g. Wanjiku Kamau',
                            Icons.person_outline),
                        validator: (v) => (v == null || v.trim().length < 2)
                            ? 'Enter your full name' : null,
                        autovalidateMode: AutovalidateMode.onUserInteraction),
                    const SizedBox(height: 14),
                  ],

                  _label('Email address'),
                  TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: _dec('student@university.ac.ke',
                          Icons.email_outlined),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email required';
                        if (!v.contains('@')) return 'Invalid email';
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction),
                  const SizedBox(height: 14),

                  _label('Password'),
                  TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: _dec('••••••••', Icons.lock_outline,
                          suffix: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                                  size: 20, color: muted),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure))),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Minimum 6 characters' : null,
                      autovalidateMode: AutovalidateMode.onUserInteraction),

                  if (!_isReg)
                    Align(alignment: Alignment.centerRight,
                        child: TextButton(
                            onPressed: () {},
                            child: const Text('Forgot password?',
                                style: TextStyle(
                                    color: green, fontSize: 12)))),
                  const SizedBox(height: 6),

                  if (_serverErr != null) ...[
                    Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: error.withValues(alpha: 0.4))),
                        child: Row(children: [
                          const Icon(Icons.error_outline, color: error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_serverErr!,
                              style: const TextStyle(color: error, fontSize: 13))),
                        ])),
                    const SizedBox(height: 12),
                  ],

                  SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                              : Text(_isReg ? 'Create account' : 'Sign in',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w500)))),
                  const SizedBox(height: 12),

                  SizedBox(
                      width: double.infinity, height: 50,
                      child: OutlinedButton(
                          onPressed: () => setState(() {
                            _isReg = !_isReg; _serverErr = null;
                            _formKey.currentState?.reset();
                          }),
                          child: Text(_isReg
                              ? 'Already have an account? Sign in'
                              : "Don't have an account? Register",
                              style: const TextStyle(fontSize: 13)))),

                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(children: [
                        const Expanded(child: Divider()),
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('or',
                                style: TextStyle(color: muted, fontSize: 13))),
                        const Expanded(child: Divider()),
                      ])),

                  InkWell(
                    onTap: () {
                      context.read<AuthService>().continueOffline();
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isDark
                                    ? const Color(0xFF2C2F3A)
                                    : const Color(0xFFE5E7EB))),
                        child: Row(children: [
                          const Icon(Icons.wifi_off_rounded, color: green),
                          const SizedBox(width: 12),
                          Column(crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Continue offline',
                                    style: TextStyle(fontWeight: FontWeight.w500)),
                                Text('No account needed',
                                    style: TextStyle(fontSize: 12, color: muted)),
                              ]),
                          const Spacer(),
                          Icon(Icons.arrow_forward_ios,
                              size: 14, color: muted),
                        ])),
                  ),
                ]),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(t, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w500)));

  InputDecoration _dec(String hint, IconData icon, {Widget? suffix}) =>
      InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 20),
          suffixIcon: suffix);
}
