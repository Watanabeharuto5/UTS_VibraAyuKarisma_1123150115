class ApiConstant {
  
  static const String baseUrl = 'http://192.168.110.203:8080/v1';

  
  static const String verifyToken = '$baseUrl/auth/verify-token';

  
  static const String products = '$baseUrl/products';

  
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;
}