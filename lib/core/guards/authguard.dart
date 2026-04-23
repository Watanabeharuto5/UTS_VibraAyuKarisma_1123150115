import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;

    return switch (status) {
      AuthStatus.authenticated    => child,                   //  Lanjut ke halaman tujuan
      AuthStatus.emailNotVerified => const VerifyEmailPage(), //  Redirect ke verifikasi email
      _                           => const LoginPage(),       //  Redirect ke login
    };
  }
}