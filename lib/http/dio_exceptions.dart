import 'package:dio/dio.dart';

class DioExceptions implements Exception {
  late String message;

  DioExceptions.fromDioError(DioException dioException) {
    dynamic error = dioException.response?.data;
    String? reason = error is Map
        ? (error['reason'] as String?)
        : (error is String ? error : null);
    if (reason != null) {
      message = reason;
    } else {
      message = 'Please try again';
    }
  }

  @override
  String toString() => message;
}
