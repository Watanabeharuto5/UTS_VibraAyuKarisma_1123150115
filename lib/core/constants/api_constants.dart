class ApiConstant {
  static const String baseUrl = 'http://10.104.145.204:8080/v1';

  //auth endpoints
  static const String verifyToken = '/auth/verify-token';

  //product endpoints
  static const String products = '/products';

  //timeouts
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;
}