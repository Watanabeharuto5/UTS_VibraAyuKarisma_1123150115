import 'package:equatable/equatable.dart';
import 'product_model.dart';

class CartItemModel extends Equatable {
  final int id;
  final int userId;
  final int productId;
  final int quantity;
  final ProductModel product;

  const CartItemModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.product,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['ID'] as int? ?? json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      productId: json['product_id'] as int? ?? 0,
      quantity: json['quantity'] as int? ?? 1,
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>? ?? {}),
    );
  }

  @override
  List<Object?> get props => [id, userId, productId, quantity, product];
}
