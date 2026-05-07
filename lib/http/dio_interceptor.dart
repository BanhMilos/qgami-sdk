import 'dart:io';
import 'package:dio/dio.dart';

class DioInterceptor extends Interceptor {
  final Dio dio;

  DioInterceptor({required this.dio});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;

    if (statusCode == HttpStatus.unauthorized &&
        ![
          '/api/v1/fe/logout',
          '/api/v1/fe/user/change-password',
          '/api/v1/fe/user/delete-account',
        ].contains(err.requestOptions.path)) {
      if (!AuthInterceptorState.isHandlingUnauthorized) {
        AuthInterceptorState.isHandlingUnauthorized = true;

        // reset flag after a short delay (important)
        Future.delayed(const Duration(seconds: 2), () {
          AuthInterceptorState.isHandlingUnauthorized = false;
        });
      }
    }

    return handler.reject(err);
  }
}

class AuthInterceptorState {
  static bool isHandlingUnauthorized = false;
}
