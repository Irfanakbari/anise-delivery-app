import 'package:dio/dio.dart';
import 'package:get/instance_manager.dart';

import '../controllers/global_controller.dart';

class CustomInterceptors extends Interceptor {
  final GlobalController globalController =
      Get.find<GlobalController>(); // Inisialisasi controller
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    var token = globalController.token;
    options.headers['Authorization'] = 'Bearer $token';
    super.onRequest(options, handler);
  }

  @override
  Future onError(DioException err, ErrorInterceptorHandler handler) async {
    super.onError(err, handler);
  }
}
