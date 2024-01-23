import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hpm_outgoing_app/main.dart';

class DioClient {
  DioClient() {
    addInterceptor(CustomInterceptors());
  }

  final Dio dio = Dio(BaseOptions(
    baseUrl: 'https://api.vuteq.co.id/v1/ansei',
  ));

  void addInterceptor(Interceptor interceptor) {
    dio.interceptors.add(interceptor);
  }
}

class CustomInterceptors extends Interceptor {
  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    debugPrint('REQUEST[${options.method}] => PATH: ${options.path}');
    var token = keycloakWrapper.accessToken;
    // add headers bearer token
    options.headers['Authorization'] = 'Bearer $token';
    debugPrint(options.headers.toString());
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint(
        'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
    super.onResponse(response, handler);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final dio = DioClient().dio;
    debugPrint('ERROR[${err.response}] => PATH: ${err.requestOptions.path}');

    try {
      // Check if the error has a response and a status code
      if (err.response != null && err.response?.statusCode != null) {
        // debugPrint(
        //     'ERROR[${err.response!.statusCode}] => PATH: ${err.requestOptions.path} => MESSAGE: ${err.response!.data}');

        // Check if the error is due to token expiration
        if (err.response!.statusCode == 401) {
          // Attempt to refresh the token
          debugPrint(err.response!.statusCode.toString());
          bool tokenRefreshed = await keycloakWrapper.renewToken();
          var token = keycloakWrapper.accessToken;

          if (tokenRefreshed) {
            // If token refresh is successful, retry the failed request
            RequestOptions options = err.requestOptions;
            options.headers['Authorization'] = 'Bearer $token';
            // Change the line below to use Options instead of RequestOptions
            Options requestOptions = Options(
              method: options.method,
              headers: options.headers,
            );

            return handler.resolve(
                await dio.request(options.path, options: requestOptions));
          }
        }
      } else {
        // Handle other errors without a response or status code
        debugPrint('ERROR => ${err.message}');
      }
    } catch (e) {
      // Handle any exceptions that might occur during token renewal
      debugPrint('ERROR during token renewal => $e');
    }

    super.onError(err, handler);
  }
}
