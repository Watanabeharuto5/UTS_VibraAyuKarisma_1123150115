import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

import '../providers/auth_provider.dart';
import '../../../../core/routes/app_router.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/divider_with_text.dart';
import '../widgets/google_sign_in_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPass = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _loginEmail() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.loginWithEmail(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (!mounted) return;
    _handleLoginResult(ok, auth);
  }

  Future<void> _loginGoogle() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.loginWithGoogle();
    if (!mounted) return;
    _handleLoginResult(ok, auth);
  }

  void _handleLoginResult(bool ok, AuthProvider auth) {
    if (ok) {
      Navigator.pushReplacementNamed(context, AppRouter.dashboard);
    } else if (auth.status == AuthStatus.emailNotVerified) {
      Navigator.pushReplacementNamed(context, AppRouter.verifyEmail);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Login gagal'),
          backgroundColor: const Color(0xFFC0392B),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return LoadingOverlay(
      isLoading: isLoading,
      message: 'Processing...',
      child: Scaffold(
        backgroundColor: const Color(0xFF111111),
        body: Stack(
          children: [
            const Positioned(
              top: 60, left: 24,
              child: Text('✦', style: TextStyle(color: Color(0xFFC8B47A), fontSize: 26)),
            ),
            const Positioned(
              bottom: 40, right: 24,
              child: Text('✦', style: TextStyle(color: Color(0xFFC8B47A), fontSize: 20)),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      const Text('✦',
                        style: TextStyle(color: Color(0xFFC8B47A), fontSize: 22, letterSpacing: 4)),
                      const SizedBox(height: 10),
                      const Text(
                        'KPOP\nALBUMS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFE8D9B0),
                          letterSpacing: 5,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Enter to discover the albums',
                        style: TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 12,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 40),
                      CustomTextField(
                        label: '',
                        hint: 'Email',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.alternate_email, color: Color(0xFF666666)),
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: '',
                        hint: 'Password',
                        controller: _passCtrl,
                        obscureText: !_showPass,
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF666666)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPass ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0xFF666666),
                            size: 18,
                          ),
                          onPressed: () => setState(() => _showPass = !_showPass),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(color: Color(0xFF888888), fontSize: 11.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomButton(
                        label: 'JOIN THE FANDOM',
                        onPressed: _loginEmail,
                        isLoading: isLoading,
                      ),
                      const SizedBox(height: 24),
                      const DividerWithText(text: 'or sign in with'),
                      const SizedBox(height: 20),
                      GoogleSignInButton(
                        onPressed: _loginGoogle,
                        isLoading: isLoading,
                      ),
                      const SizedBox(height: 36),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'New Fan? Register Here ',
                            style: TextStyle(color: Color(0xFF555555), fontSize: 11.5),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacementNamed(context, AppRouter.register),
                            child: const Text(
                              'Daftar',
                              style: TextStyle(
                                color: Color(0xFFC8B47A),
                                fontWeight: FontWeight.w600,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}