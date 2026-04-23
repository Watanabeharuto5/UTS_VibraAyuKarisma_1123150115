import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../../../features/dashboard/data/Models/product_model.dart';
import '../../../../core/services/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

enum ProductStatus { initial, loading, loaded, error }

class ProductProvider extends ChangeNotifier {
  ProductStatus _status = ProductStatus.initial;
  List<ProductModel> _products = [];
  String? _error;

  // ─── GETTERS ─────────────────────────────────────────────
  ProductStatus get status => _status;
  List<ProductModel> get products => _products;
  String? get error => _error;
  bool get isLoading => _status == ProductStatus.loading;

  // ─── FETCH PRODUCTS ─────────────────────────────────────
  Future<void> fetchProducts() async {
    _status = ProductStatus.loading;
    notifyListeners();

    try {
      final response =
          await DioClient.instance.get(ApiConstant.products);

      final List data = response.data['data'] ?? [];

      _products =
          data.map((e) => ProductModel.fromJson(e)).toList();

      _status = ProductStatus.loaded;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ??
          'Gagal memuat produk';
      _status = ProductStatus.error;
    } catch (e) {
      _error = 'Terjadi kesalahan tidak diketahui';
      _status = ProductStatus.error;
    }

    notifyListeners();
  }
}