import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../data/models/cart_model.dart';
import '../../data/models/transaction_model.dart';
import '../../../../core/services/dio_client.dart';
import '../../../../core/services/notification_service.dart';

enum CartStatus { initial, loading, loaded, error }

class CartProvider extends ChangeNotifier {
  CartStatus _status = CartStatus.initial;
  List<CartItemModel> _cartItems = [];
  String? _error;

  // Getters
  CartStatus get status => _status;
  List<CartItemModel> get cartItems => _cartItems;
  String? get error => _error;
  bool get isLoading => _status == CartStatus.loading;

  // Hitung total item unik di keranjang
  int get itemCount => _cartItems.length;

  // Hitung total kuantitas produk di keranjang
  int get totalQuantity => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  // Hitung total harga belanjaan di keranjang
  double get totalPrice => _cartItems.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));

  // Ambil data keranjang dari backend
  Future<void> fetchCart() async {
    // Hanya tampilkan loading screen jika keranjang benar-benar kosong
    if (_cartItems.isEmpty) {
      _status = CartStatus.loading;
    }
    _error = null;
    notifyListeners();

    try {
      final response = await DioClient.instance.get('/cart');
      final List data = response.data['data'] ?? [];

      _cartItems = data.map((e) => CartItemModel.fromJson(e)).toList();
      _status = CartStatus.loaded;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Gagal mengambil data keranjang';
      if (_cartItems.isEmpty) {
        _status = CartStatus.error;
      }
    } catch (e) {
      _error = 'Terjadi kesalahan saat mengambil keranjang';
      if (_cartItems.isEmpty) {
        _status = CartStatus.error;
      }
    }

    notifyListeners();
  }

  // Tambahkan produk ke keranjang
  Future<bool> addToCart(int productId, int quantity) async {
    if (_cartItems.isEmpty) {
      _status = CartStatus.loading;
      notifyListeners();
    }
    _error = null;

    try {
      await DioClient.instance.post(
        '/cart',
        data: {'product_id': productId, 'quantity': quantity},
      );

      // Refresh keranjang setelah menambah
      await fetchCart();

      // Kirim notifikasi local
      try {
        final addedItem = _cartItems.firstWhere((item) => item.productId == productId);
        await NotificationService.showNotification(
          id: productId,
          title: 'Berhasil Masuk Keranjang 🛒',
          body: '${addedItem.product.name} (x$quantity) telah ditambahkan.',
        );
      } catch (_) {
        await NotificationService.showNotification(
          id: productId,
          title: 'Berhasil Masuk Keranjang 🛒',
          body: 'Produk berhasil ditambahkan ke keranjang belanja.',
        );
      }

      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Gagal menambahkan produk ke keranjang';
      _status = CartStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Terjadi kesalahan saat menambahkan produk';
      _status = CartStatus.error;
      notifyListeners();
      return false;
    }
  }

  // Perbarui kuantitas produk di keranjang
  Future<bool> updateQuantity(int itemId, int quantity) async {
    _error = null;

    try {
      await DioClient.instance.put(
        '/cart/$itemId',
        data: {'quantity': quantity},
      );

      // Refresh keranjang setelah update
      await fetchCart();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Gagal memperbarui kuantitas';
      _status = CartStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Terjadi kesalahan saat memperbarui kuantitas';
      _status = CartStatus.error;
      notifyListeners();
      return false;
    }
  }

  // Hapus produk dari keranjang
  Future<bool> removeFromCart(int itemId) async {
    _error = null;

    try {
      await DioClient.instance.delete('/cart/$itemId');

      // Refresh keranjang setelah hapus
      await fetchCart();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Gagal menghapus produk dari keranjang';
      _status = CartStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Terjadi kesalahan saat menghapus produk';
      _status = CartStatus.error;
      notifyListeners();
      return false;
    }
  }

  // Proses checkout keranjang
  Future<bool> checkout(String paymentMethod) async {
    _status = CartStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final response = await DioClient.instance.post(
        '/cart/checkout',
        data: {'payment_method': paymentMethod},
      );

      final txData = response.data['data'] ?? {};
      final invoiceNum = txData['invoice_number'] ?? 'TRX-${DateTime.now().millisecondsSinceEpoch}';

      _cartItems = [];
      _status = CartStatus.loaded;
      notifyListeners();

      // Kirim notifikasi local
      await NotificationService.showNotification(
        id: 999,
        title: 'Pembayaran Berhasil!',
        body: 'Pesanan dengan nomor $invoiceNum sedang diproses.',
      );

      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Gagal melakukan checkout';
      _status = CartStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Terjadi kesalahan saat memproses checkout';
      _status = CartStatus.error;
      notifyListeners();
      return false;
    }
  }

  List<TransactionModel> _history = [];
  List<TransactionModel> get history => _history;

  // Ambil riwayat transaksi dari backend
  Future<void> fetchHistory() async {
    _status = CartStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final response = await DioClient.instance.get('/transactions');
      final List data = response.data['data'] ?? [];

      _history = data.map((e) => TransactionModel.fromJson(e)).toList();
      _status = CartStatus.loaded;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Gagal mengambil riwayat transaksi';
      _status = CartStatus.error;
    } catch (e) {
      _error = 'Terjadi kesalahan saat mengambil riwayat';
      _status = CartStatus.error;
    }

    notifyListeners();
  }
}
