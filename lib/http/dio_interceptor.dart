import 'dart:io';
import 'package:dio/dio.dart';
import 'package:qgami_sdk/qgami.dart';

class DioInterceptor extends Interceptor {
  final Dio dio;

  DioInterceptor({required this.dio});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;

    if (statusCode == HttpStatus.unauthorized) {
      if (AuthInterceptorState.consecutiveRefreshFailures >=
          AuthInterceptorState.maxConsecutiveRefreshFailures) {
        return handler.reject(err);
      }

      final inFlight = AuthInterceptorState.refreshInFlight;
      if (inFlight != null) {
        await inFlight;
      } else {
        AuthInterceptorState.refreshInFlight = QGami.refreshAccessToken();
        final token = await AuthInterceptorState.refreshInFlight;

        if (token == null || token.isEmpty) {
          AuthInterceptorState.consecutiveRefreshFailures += 1;
        } else {
          AuthInterceptorState.consecutiveRefreshFailures = 0;
        }

        AuthInterceptorState.refreshInFlight = null;
      }
    }

    return handler.reject(err);
  }
}

class   AuthInterceptorState {
  static const int maxConsecutiveRefreshFailures = 3;
  static int consecutiveRefreshFailures = 0;
  static Future<String?>? refreshInFlight;
}
