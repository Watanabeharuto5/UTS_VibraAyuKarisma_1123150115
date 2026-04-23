import 'package:flutter/material.dart';

class ApiConstants {
  static const String baseUrl = 'http://192.168.0.28:8080/v1';

  // ================= AUTH =================
  static const String verifyToken = '/auth/verify-token';

  // ================= PRODUCT =================
  static const String products = '/products';

  // ================= TIMEOUT =================
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;
}