import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import './features/auth/presentation/providers/auth_provider.dart';
import './features/dashboard/presentation/providers/product_provider.dart';

import './core/theme/app_theme.dart';
import 'core/services/secure_storage.dart';
import './core/routes/app_router.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    print("Inisialisasi Firebase...");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase Berhasil!");
    runApp(const MyApp());
  } catch (e) {
    print("Firebase Error: $e");
    // Tetap jalankan aplikasi biar nggak hitam, nanti errornya muncul di UI
    runApp(const MyApp()); 
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: MaterialApp(
        title: 'My App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRouter.splash,
        routes: AppRouter.routes,
      ),
    );
  }
}

// Splash Page
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final token = await SecureStorageService.getToken();

    final route = token != null
        ? AppRouter.dashboard
        : AppRouter.login;

    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}