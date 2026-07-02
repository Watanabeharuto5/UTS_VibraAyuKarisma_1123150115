import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/dio_client.dart';
import '../../../../core/services/secure_storage.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/divider_with_text.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/auth_header.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});
  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  Timer? _timer;
  bool _resendCooldown = false;
  int _countdown = 60;

  @override
  void initState() {
    super.initState();
    _startPolling(); // ✅ TIDAK DIUBAH
  }

  @override
  void dispose() {
    _timer?.cancel(); // ✅ TIDAK DIUBAH
    super.dispose();
  }

  // ✅ TIDAK DIUBAH
  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final success = await auth.checkEmailVerified();
      if (success && mounted) {
        _timer?.cancel();
        Navigator.pushReplacementNamed(context, AppRouter.dashboard);
      }
    });
  }

  // ✅ TIDAK DIUBAH
  Future<void> _resendEmail() async {
    if (_resendCooldown) return;
    await context.read<AuthProvider>().resendVerificationEmail();

    setState(() { _resendCooldown = true; _countdown = 60; });
    Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() { _countdown--; });
      if (_countdown <= 0) {
        t.cancel();
        setState(() => _resendCooldown = false);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email verifikasi sudah dikirim ulang')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().firebaseUser; // ✅ TIDAK DIUBAH

    return Scaffold(
      backgroundColor: const Color(0xFF111111), // 🎨 background hitam
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // 🎨 DIUBAH: ganti AuthHeader jadi manual biar bisa custom warna
              const Text(
                '✦',
                style: TextStyle(color: Color(0xFFC8B47A), fontSize: 22, letterSpacing: 4),
              ),
              const SizedBox(height: 10),
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 52,
                color: Color(0xFFC8B47A), // 🎨 orange → gold
              ),
              const SizedBox(height: 16),
              const Text(
                'VERIFIKASI EMAIL',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFE8D9B0),
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kami sudah mengirim link verifikasi\nke email di bawah ini.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 12,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w300,
                ),
              ),

              const SizedBox(height: 24),

              // 🎨 DIUBAH: warna container email
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFC8B47A).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  user?.email ?? '-', // ✅ TIDAK DIUBAH
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE8D9B0), // 🎨 teks krem
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 🎨 DIUBAH: warna loading indicator & teks
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFC8B47A), // 🎨 gold
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Menunggu konfirmasi...',
                  style: TextStyle(color: Color(0xFF888888)),
                ),
              ]),

              const SizedBox(height: 32),

              // ✅ TIDAK DIUBAH — label & logic cooldown sama persis
              CustomButton(
                label: _resendCooldown
                    ? 'Kirim Ulang ($_countdown detik)'
                    : 'Kirim Ulang Email',
                variant: ButtonVariant.outlined,
                onPressed: _resendCooldown ? null : _resendEmail,
              ),

              const SizedBox(height: 16),

              // ✅ TIDAK DIUBAH
              CustomButton(
                label: 'Ganti Akun / Logout',
                variant: ButtonVariant.text,
                onPressed: () {
                  context.read<AuthProvider>().logout();
                  Navigator.pushReplacementNamed(context, AppRouter.login);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}