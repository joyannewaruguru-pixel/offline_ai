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
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    setState(() => _serverErr = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthService>();
      final err = _isReg ? await auth.register(_nameCtrl.text.trim(), _emailCtrl.text.trim(), _passCtrl.text) : await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;
      if (err == null) { Navigator.pushReplacementNamed(context, '/dashboard'); }
      else { setState(() => _serverErr = err); }
    } catch (_) { setState(() => _serverErr = 'Error'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const green = Color(0xFF1D9E75); const error = Color(0xFFE24B4A);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(children: [
              if (_isReg) TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              TextFormField(controller: _passCtrl, obscureText: _obscure, decoration: InputDecoration(labelText: 'Password', suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscure = !_obscure)))),
              if (_serverErr != null) Text(_serverErr!, style: const TextStyle(color: error)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _loading ? null : _submit, child: Text(_isReg ? 'Register' : 'Login')),
              TextButton(onPressed: () => setState(() => _isReg = !_isReg), child: Text(_isReg ? 'Login instead' : 'Register instead')),
            ]),
          ),
        ),
      ),
    );
  }
}
