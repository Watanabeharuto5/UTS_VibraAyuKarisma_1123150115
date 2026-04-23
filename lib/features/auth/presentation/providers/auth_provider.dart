import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/services/dio_client.dart';
import '../../../../core/services/secure_storage.dart';
import '../../../../core/constants/api_constants.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  emailNotVerified,
  error,
}

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ─── State ───────────────────────────────────────────────
  AuthStatus _status = AuthStatus.initial;
  User? _firebaseUser;
  String? _backendToken;
  String? _errorMessage;

  String? _tempEmail;
  String? _tempPassword;

  // ─── Getters ─────────────────────────────────────────────
  AuthStatus get status => _status;
  User? get firebaseUser => _firebaseUser;
  String? get backendToken => _backendToken;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;

  // ─── REGISTER ────────────────────────────────────────────
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _firebaseUser = credential.user;

      await _firebaseUser?.updateDisplayName(name);
      await _firebaseUser?.sendEmailVerification();

      _tempEmail = email;
      _tempPassword = password;

      _status = AuthStatus.emailNotVerified;
      notifyListeners();

      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e.code));
      return false;
    }
  }

  // ─── LOGIN AFTER EMAIL VERIFIED ───────────────────────────
  Future<bool> loginAfterEmailVerification() async {
    _setLoading();

    try {
      await _firebaseUser?.reload();
      _firebaseUser = _auth.currentUser;

      if (!(_firebaseUser?.emailVerified ?? false)) {
        _status = AuthStatus.emailNotVerified;
        notifyListeners();
        return false;
      }

      if (_tempEmail == null || _tempPassword == null) {
        _setError("Session expired, silakan login ulang");
        return false;
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: _tempEmail!,
        password: _tempPassword!,
      );

      _firebaseUser = credential.user;
      _tempEmail = null;
      _tempPassword = null;

      return await _verifyTokenToBackend();
    } catch (e) {
      _setError("Gagal verifikasi email");
      return false;
    }
  }

  // ─── VERIFY TOKEN KE BACKEND ─────────────────────────────
  Future<bool> _verifyTokenToBackend() async {
    try {
      final firebaseToken = await _firebaseUser?.getIdToken(true);
      print("TOKEN YANG DIKIRIM: $firebaseToken");

      // Gunakan instance Dio baru atau bypass header
      final response = await DioClient.instance.post(
        ApiConstant.verifyToken,
        data: {'firebase_token': firebaseToken},
        options: Options(
          headers: {
            // Kita kirim Firebase Token di Header Authorization
            // karena biasanya backend Go mengeceknya di sana
            'Authorization': 'Bearer $firebaseToken',
          },
        ),
      );

      // Sesuaikan mapping data dengan response JSON Golang kamu
      // Jika backend kamu mengembalikan { "data": { "token": "..." } }
      final data = response.data['data'];
      final token = data['token'] ?? data['access_token'];

      _backendToken = token;
      await SecureStorageService.saveToken(token);

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Detail Error Backend: $e"); // Cek di console log
      _setError("Gagal verifikasi ke server");
      return false;
    }
  }

  // ─── LOGIN EMAIL ─────────────────────────────────────────
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _firebaseUser = credential.user;

      if (!(_firebaseUser?.emailVerified ?? false)) {
        _status = AuthStatus.emailNotVerified;
        notifyListeners();
        return false;
      }

      return await _verifyTokenToBackend();
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e.code));
      return false;
    }
  }

  // ─── LOGIN GOOGLE ────────────────────────────────────────
  Future<bool> loginWithGoogle() async {
    _setLoading();

    try {
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _setError('Login Google dibatalkan');
        return false;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      _firebaseUser = userCred.user;

      return await _verifyTokenToBackend();
    } catch (e) {
      _setError('Gagal login Google');
      return false;
    }
  }

  // ─── RESEND EMAIL ────────────────────────────────────────
  Future<void> resendVerificationEmail() async {
    await _firebaseUser?.sendEmailVerification();
  }

  // ─── CHECK EMAIL VERIFIED ────────────────────────────────
  Future<bool> checkEmailVerified() async {
    await _firebaseUser?.reload();
    _firebaseUser = _auth.currentUser;

    if (_firebaseUser?.emailVerified ?? false) {
      return await _verifyTokenToBackend();
    }

    return false;
  }

  // ─── LOGOUT ──────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    await SecureStorageService.clearAll();

    _firebaseUser = null;
    _backendToken = null;
    _status = AuthStatus.unauthenticated;

    notifyListeners();
  }

  // ─── HELPER ──────────────────────────────────────────────
  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  String _mapFirebaseError(String code) => switch (code) {
    'email-already-in-use' => 'Email sudah terdaftar. Gunakan email lain.',
    'user-not-found' => 'Akun tidak ditemukan. Silakan daftar.',
    'wrong-password' => 'Password salah. Coba lagi.',
    'invalid-email' => 'Format email tidak valid.',
    'weak-password' => 'Password terlalu lemah. Minimal 6 karakter.',
    'network-request-failed' => 'Tidak ada koneksi internet.',
    _ => 'Terjadi kesalahan. Coba lagi.',
  };
}