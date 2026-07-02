import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:email_validator/email_validator.dart';
import '../providers/auth_provider.dart';
import '../../../../core/routes/app_router.dart';
import '../widgets/auth_header.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_overlay.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  bool _showPass = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  // ✅ TIDAK DIUBAH
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );

    if (!mounted) return;
    if (success) {
      Navigator.pushReplacementNamed(context, AppRouter.verifyEmail);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Pendaftaran gagal'),
          backgroundColor: const Color(0xFFC0392B), // 🎨 merah disesuaikan
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return LoadingOverlay(
      isLoading: isLoading,
      message: 'Mendaftarkan akun...', // ✅ TIDAK DIUBAH
      child: Scaffold(
        backgroundColor: const Color(0xFF111111), // 🎨 background hitam
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // 🎨 DIUBAH: ganti AuthHeader jadi manual biar bisa custom warna
                  const Text(
                    '✦',
                    style: TextStyle(color: Color(0xFFC8B47A), fontSize: 22, letterSpacing: 4),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'BUAT AKUN',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFE8D9B0),
                      letterSpacing: 5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Lengkapi data diri untuk bergabung',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 12,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w300,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ✅ TIDAK DIUBAH — validator & controller sama persis
                  CustomTextField(
                    label: 'Nama Lengkap',
                    hint: 'Masukkan nama lengkap',
                    controller: _nameCtrl,
                    prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF666666)),
                    validator: (v) =>
                        (v?.isEmpty ?? true) ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Email',
                    hint: 'contoh@email.com',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF666666)),
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Email wajib diisi';
                      if (!EmailValidator.validate(v!)) return 'Format email salah';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Password',
                    hint: 'Minimal 8 karakter',
                    controller: _passCtrl,
                    obscureText: !_showPass,
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF666666)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPass ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFF666666),
                      ),
                      onPressed: () => setState(() => _showPass = !_showPass),
                    ),
                    validator: (v) => (v?.length ?? 0) < 8
                        ? 'Password minimal 8 karakter'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Konfirmasi Password',
                    hint: 'Ulangi password',
                    controller: _pass2Ctrl,
                    obscureText: !_showPass,
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF666666)),
                    validator: (v) =>
                        v != _passCtrl.text ? 'Password tidak cocok' : null,
                  ),
                  const SizedBox(height: 28),

                  // ✅ TIDAK DIUBAH
                  CustomButton(
                    label: 'Daftar Sekarang',
                    onPressed: _register,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 16),

                  // 🎨 DIUBAH: warna teks disesuaikan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Sudah punya akun? ',
                        style: TextStyle(color: Color(0xFF555555), fontSize: 13),
                      ),
                      GestureDetector(
                        // ✅ TIDAK DIUBAH
                        onTap: () => Navigator.pushReplacementNamed(
                          context,
                          AppRouter.login,
                        ),
                        child: const Text(
                          'Masuk',
                          style: TextStyle(
                            color: Color(0xFFC8B47A), // 🎨 biru → gold
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
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
      ),
    );
  }
}