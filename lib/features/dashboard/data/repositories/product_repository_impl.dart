import '../../domain/repositories/product_repository.dart';
import '../../../../core/services/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../dashboard/data/models/product_model.dart';
class ProductRepositoryImpl implements ProductRepository {
  @override
  Future<List<ProductModel>> getProducts({
    int page = 1,
    int limit = 10,
    String? category,
  }) async {
    final response = await DioClient.instance.get(
      ApiConstant.products,
      queryParameters: {'page': page, 'limit': limit, 'category': category},
    );

    final List<dynamic> data = response.data['data'];
    return data.map((e) => ProductModel.fromJson(e)).toList();
  }

  @override
  Future<ProductModel> getProductById(int id) async {
    final response = await DioClient.instance.get(
      '${ApiConstant.products}/$id',
    );
    return ProductModel.fromJson(response.data['data']);
  }
}