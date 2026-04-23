import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../constants/api_constants.dart';
import '../service/secure_storage.dart';

class DioClient {

  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDio(); // Singleton pattern
    return _instance!;
  }


  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: Duration(
          milliseconds: ApiConstants.connectTimeout,
        ),
        receiveTimeout: Duration(
          milliseconds: ApiConstants.receiveTimeout,
        ),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );


    // ================= INTERCEPTOR: LOGGING =================
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          debugPrint('[REQUEST] ${options.method} ${options.path}');
          handler.next(options);
        },

        onResponse: (response, handler) {
          debugPrint('[RESPONSE] ${response.statusCode}');
          handler.next(response);
        },

        onError: (error, handler) async {
          debugPrint('[ERROR] ${error.response?.statusCode}');

          if (error.response?.statusCode == 401) {
            await SecureStorageService.clearAll(); // Auto logout
          }

          handler.next(error);
        },
      ),
    );


    // ================= INTERCEPTOR: TOKEN =================
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorageService.getToken();

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
      ),
    );

    return dio;
  }

}