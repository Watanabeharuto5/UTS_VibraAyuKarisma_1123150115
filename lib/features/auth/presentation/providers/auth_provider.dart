import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Representasi kondisi autentikasi
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

  // ─── Register dengan Email & Password ────────────────────
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
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ─── Login setelah email diverifikasi ────────────────────
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

      final credential = await _auth.signInWithEmailAndPassword(
        email: _tempEmail!,
        password: _tempPassword!,
      );

      _firebaseUser = credential.user;
      _tempEmail = null;
      _tempPassword = null;

      return await _verifyTokenToBackend();
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ─── Verify Token ke Backend ─────────────────────────────
  Future<bool> _verifyTokenToBackend() async {
    final firebaseToken = await _firebaseUser?.getIdToken();

    final response = await DioClient.instance.post(
      ApiConstants.verifyToken,
      data: {'firebase_token': firebaseToken},
    );

    final data = response.data['data'] as Map<String, dynamic>;
    final backendToken = data['access_token'] as String;

    await SecureStorageService.saveToken(backendToken);

    _backendToken = backendToken;
    _status = AuthStatus.authenticated;
    notifyListeners();

    return true;
  }

  // ─── Login dengan Email & Password ───────────────────────
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

  // ─── Login dengan Google ─────────────────────────────────
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
      _setError('Gagal login dengan Google: $e');
      return false;
    }
  }

  // ─── Kirim ulang email verifikasi ────────────────────────
  Future<void> resendVerificationEmail() async {
    await _firebaseUser?.sendEmailVerification();
  }

  // ─── Cek status verifikasi email ─────────────────────────
  Future<bool> checkEmailVerified() async {
    await _firebaseUser?.reload();
    _firebaseUser = _auth.currentUser;

    if (_firebaseUser?.emailVerified ?? false) {
      return await _verifyTokenToBackend();
    }
    return false;
  }

  // ─── Logout ──────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    await SecureStorageService.clearAll();

    _firebaseUser = null;
    _backendToken = null;
    _status = AuthStatus.unauthenticated;

    notifyListeners();
  }

  // ─── Helper Functions ────────────────────────────────────
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
        'email-already-in-use' =>
          'Email sudah terdaftar. Gunakan email lain.',
        'user-not-found' =>
          'Akun tidak ditemukan. Silakan daftar.',
        'wrong-password' =>
          'Password salah. Coba lagi.',
        'invalid-email' =>
          'Format email tidak valid.',
        'weak-password' =>
          'Password terlalu lemah. Minimal 6 karakter.',
        'network-request-failed' =>
          'Tidak ada koneksi internet.',
        _ => 'Terjadi kesalahan. Coba lagi.',
      };
}