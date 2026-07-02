import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import './features/auth/presentation/providers/auth_provider.dart';
import './features/dashboard/presentation/providers/product_provider.dart';
import './features/dashboard/presentation/providers/cart_provider.dart';

import './core/theme/app_theme.dart';
import 'core/services/secure_storage.dart';
import './core/routes/app_router.dart';

void main() async {
  // 1. Pastikan binding inisialisasi duluan
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print("Inisialisasi Firebase...");
    
    // 2. Cegah error [core/duplicate-app] dengan cek apakah sudah ada app yang aktif
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    
    print("Firebase Berhasil!");
  } catch (e) {
    // Mencetak error jika ada masalah lain saat inisialisasi
    print("Firebase Note: $e");
  }

  // 3. Jalankan aplikasi
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
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

// Splash Page - Pintu masuk aplikasi
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
    // Delay 2 detik biar loadingnya kelihatan
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Cek token dari Secure Storage (untuk auto-login)
    final token = await SecureStorageService.getToken();

    // Jika token ada, masuk ke dashboard. Jika tidak, ke login.
    final route = token != null
        ? AppRouter.dashboard
        : AppRouter.login;

    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // Background putih biar gak item layarnya
      backgroundColor: Colors.white, 
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}