import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../data/models/product_model.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';

enum ProductStatus { initial, loading, loaded, error }

class ProductProvider extends ChangeNotifier {
  ProductStatus _status = ProductStatus.initial;
  List<ProductModel> _products = [];
  String? _error;

  // ─── Getters ─────────────────────────────────────────────
  ProductStatus get status => _status;
  List<ProductModel> get products => _products;
  String? get error => _error;
  bool get isLoading => _status == ProductStatus.loading;

  // ─── Fetch Products dari API ─────────────────────────────
  Future<void> fetchProducts() async {
    // 1. Set loading → UI tampil spinner
    _status = ProductStatus.loading;
    notifyListeners();

    try {
      // 2. Hit API (Bearer token otomatis dari interceptor Dio)
      final response =
          await DioClient.instance.get(ApiConstants.products);

      // 3. Ambil data JSON → convert ke List<ProductModel>
      final List<dynamic> data = response.data['data'];

      _products = data
          .map((e) => ProductModel.fromJson(e))
          .toList();

      // 4. Sukses → ubah status
      _status = ProductStatus.loaded;
    } on DioException catch (e) {
      // 5. Error handling
      _error = e.response?.data['message'] ?? 'Gagal memuat produk';
      _status = ProductStatus.error;
    }

    // 6. Update UI
    notifyListeners();
  }
}