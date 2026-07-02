import 'package:equatable/equatable.dart';
import 'product_model.dart';

class TransactionModel extends Equatable {
  final int id;
  final String invoiceNumber;
  final double totalPrice;
  final String status;
  final String paymentMethod;
  final String createdAt;
  final List<TransactionItemModel> items;

  const TransactionModel({
    required this.id,
    required this.invoiceNumber,
    required this.totalPrice,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    required this.items,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List? ?? [];
    return TransactionModel(
      id: json['ID'] as int? ?? json['id'] as int? ?? 0,
      invoiceNumber: json['invoice_number'] as String? ?? '',
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'Selesai',
      paymentMethod: json['payment_method'] as String? ?? '',
      createdAt: json['CreatedAt'] as String? ?? json['created_at'] as String? ?? '',
      items: rawItems.map((e) => TransactionItemModel.fromJson(e)).toList(),
    );
  }

  @override
  List<Object?> get props => [id, invoiceNumber, totalPrice, status, paymentMethod, createdAt, items];
}

class TransactionItemModel extends Equatable {
  final int id;
  final int transactionId;
  final int productId;
  final int quantity;
  final double price;
  final ProductModel product;

  const TransactionItemModel({
    required this.id,
    required this.transactionId,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.product,
  });

  factory TransactionItemModel.fromJson(Map<String, dynamic> json) {
    return TransactionItemModel(
      id: json['ID'] as int? ?? json['id'] as int? ?? 0,
      transactionId: json['transaction_id'] as int? ?? 0,
      productId: json['product_id'] as int? ?? 0,
      quantity: json['quantity'] as int? ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>? ?? {}),
    );
  }

  @override
  List<Object?> get props => [id, transactionId, productId, quantity, price, product];
}
