import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/constants.dart';
import '../utils/theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool loading = false;
  String? error;

  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _nameC = TextEditingController();
  final _uniC = TextEditingController();
  String _selectedSubject = 'Mathematics';
  bool _obscure = true;

  @override
  void dispose() {
    _emailC.dispose(); _passC.dispose(); _nameC.dispose(); _uniC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { loading = true; error = null; });
    final state = context.read<AppState>();
    String? err;
    if (isLogin) {
      err = await state.login(_emailC.text.trim(), _passC.text);
    } else {
      err = await state.register(_nameC.text.trim(), _emailC.text.trim(), _passC.text, _selectedSubject, _uniC.text.trim());
    }
    if (!mounted) return;
    setState(() { loading = false; error = err; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: context.accent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text('L', style: TextStyle(color: isDark ? Colors.black : Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Lumen', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1, color: context.textColor)),
                const SizedBox(height: 4),
                Text('Study together. Pass JAMB.', style: TextStyle(fontSize: 13, color: context.textMuted)),
                const SizedBox(height: 28),

                // Tabs
                Container(
                  decoration: BoxDecoration(
                    color: context.bg2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.glassBorder),
                  ),
                  child: Row(
                    children: [
                      _tab('Sign In', isLogin, () => setState(() { isLogin = true; error = null; })),
                      _tab('Register', !isLogin, () => setState(() { isLogin = false; error = null; })),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (!isLogin) ...[
                  _field(_nameC, 'Full name', Icons.person_outline),
                  const SizedBox(height: 12),
                ],
                _field(_emailC, 'Email address', Icons.email_outlined, keyboard: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _field(_passC, 'Password', Icons.lock_outline, obscure: true),
                if (!isLogin) ...[
                  const SizedBox(height: 12),
                  _subjectDropdown(),
                  const SizedBox(height: 12),
                  _field(_uniC, 'Target University (e.g. UNILAG)', Icons.school_outlined),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.accentDim,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.glassBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star_outline, color: context.accent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: RichText(text: TextSpan(
                          style: TextStyle(fontSize: 12, color: context.textSecondary),
                          children: [
                            TextSpan(text: '${freeTrialDays}-day free trial', style: TextStyle(fontWeight: FontWeight.w800, color: context.textColor)),
                            const TextSpan(text: ' included. No payment needed to start.'),
                          ],
                        ))),
                      ],
                    ),
                  ),
                ],

                if (error != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: context.dangerColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.dangerColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: context.dangerColor, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(error!, style: TextStyle(color: context.dangerColor, fontSize: 13))),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.accent,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: loading
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? Colors.black : Colors.white))
                        : Text(isLogin ? 'Sign In' : 'Create Account', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? context.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Center(
          child: Text(label, style: TextStyle(
            fontWeight: FontWeight.w700, fontSize: 14,
            color: active ? (context.isDark ? Colors.black : Colors.white) : context.textMuted,
          )),
        ),
      ),
    ),
  );

  Widget _field(TextEditingController c, String hint, IconData icon, {TextInputType? keyboard, bool obscure = false}) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      obscureText: obscure ? _obscure : false,
      style: TextStyle(color: context.textColor, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.textMuted),
        prefixIcon: Icon(icon, color: context.textMuted, size: 18),
        suffixIcon: obscure ? IconButton(
          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: context.textMuted, size: 18),
          onPressed: () => setState(() => _obscure = !_obscure),
        ) : null,
      ),
    );
  }

  Widget _subjectDropdown() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: context.bg2,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: context.glassBorder),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _selectedSubject,
        isExpanded: true,
        dropdownColor: context.bg2,
        style: TextStyle(color: context.textColor, fontSize: 14),
        onChanged: (v) => setState(() => _selectedSubject = v!),
        items: subjects.keys.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      ),
    ),
  );
}
