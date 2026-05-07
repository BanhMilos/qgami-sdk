import 'package:dio/dio.dart';
import 'package:qgami_sdk/http/dio_interceptor.dart';

class DioClient {
  final String baseUrl;
  // receive timeout
  static const int receiveTimeout = 30;
  // connection timeout
  static const int connectionTimeout = 30;

  final Dio dio = Dio();

  DioClient({this.baseUrl = ''}) {
    dio
      ..options.baseUrl = baseUrl
      ..options.connectTimeout = const Duration(seconds: connectionTimeout)
      ..options.receiveTimeout = const Duration(seconds: receiveTimeout)
      ..options.responseType = ResponseType.json
      ..interceptors.add(DioInterceptor(dio: dio));
  }

  void setBaseUrl(String url) {
    dio.options.baseUrl = url;
  }

  void setDefaultHeaders(Map<String, String> headers) {
    dio.options.headers = headers;
  }

  void addOrUpdateHeaders(Map<String, String?> headers) {
    final existingHeaders = dio.options.headers;
    for (final entry in headers.entries) {
      existingHeaders[entry.key] = entry.value;
    }
  }

  String get getBaseUrl {
    return dio.options.baseUrl;
  }

  // method: get
  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final Response response = await dio.get(
        url,
        queryParameters: queryParameters,
        data: data,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // method: post
  Future<Response> post(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final Response response = await dio.post(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // method: put
  Future<Response> put(
    String url, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final Response response = await dio.put(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // method: delete
  Future<Response> delete(
    String url, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final Response response = await dio.delete(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
