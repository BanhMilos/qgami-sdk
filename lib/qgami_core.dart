import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:qgami_sdk/http/dio_client.dart';

class QGamiCore {
  static final QGamiCore instance = QGamiCore._();
  final _dioClient = DioClient();
  final _apiVersion = 'v1';
  final _basePath = '/user';
  String? _refreshToken = '';
  String? _accessToken = '';
  String? _deviceId = '';
  String? _sessionId = '';
  String _apiKey = '';
  QGamiCore._();
  Map<String, String> _gameUrlMap = {};

  Future<void> initialize({
    required String apiKey,
    required String environment,
    required String locale,
  }) async {
    _apiKey = apiKey;
    _dioClient.setBaseUrl(
      '${QGamiEnvironment.getApiBaseUrl(environment)}/$_apiVersion$_basePath',
    );
    final deviceId = await _getDeviceId();
    _deviceId = deviceId;
    _dioClient.setDefaultHeaders({'x-device-id': deviceId});
  }

  Future<String> _getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final info = await deviceInfo.deviceInfo;
      final data = info.data;

      const candidateKeys = [
        'identifierForVendor',
        'androidId',
        'id',
        'deviceId',
        'machineId',
        'systemGUID',
      ];

      for (final key in candidateKeys) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) {
          return value;
        }
      }
    } catch (_) {
      // Fallback below when platform info is unavailable.
    }

    return 'unknown-device';
  }

  Future<bool> identify({
    required String email,
    required String username,
    required String userId,
  }) async {
    try {
      final response = await _dioClient.post(
        '/auth/handshake',
        options: Options(
          headers: {
            'x-api-key': _apiKey,
            'x-signature':
                '1f5e6a4bd781704cfbbb9a8d72d33b2c7fd6d6e13c57c43298aa41505fb41619',
          },
        ),
        data: {'email': email, 'username': username, 'userId': userId},
      );
      final responseData = response.data;
      if (responseData['success'] == true) {
        final data = responseData['data'];
        _sessionId = data['sessionId'];
        _setTokensFromResponseData(data);
        _applyAuthHeaders();
        debugPrint('LOG : User identified successfully. Access token set.');
        return true;
      } else {
        debugPrint('LOG : Failed to identify user: ${responseData['message']}');
      }
    } catch (e) {
      debugPrint('LOG : Error identifying user: $e');
    }
    return false;
  }

  void openGame() {}

  void showFloatingWidget() {}

  void openHub() {}

  Future<String?> refreshAccessToken() async {
    try {
      debugPrint(
        'LOG : refresh headers before call: ${_dioClient.dio.options.headers}',
      );
      final response = await _dioClient.post('/auth/refresh-token');
      final responseData = response.data;
      if (responseData['success'] == true) {
        final data = responseData['data'];
        _setTokensFromResponseData(data);
        _applyAuthHeaders();
        debugPrint(
          'LOG : refresh headers after call: ${_dioClient.dio.options.headers}',
        );
        debugPrint('LOG : Token refreshed successfully. Access token set.');
        return _accessToken;
      } else {
        debugPrint('LOG : Failed to refresh token: ${responseData['message']}');
      }
    } catch (e) {
      debugPrint('LOG : Error refreshing token: $e');
    }

    return null;
  }

  void _setTokensFromResponseData(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return;
    }

    // Supports both shapes:
    // 1) { data: { token: { accessToken, refreshToken } } }
    // 2) { data: { accessToken, refreshToken } }
    final tokenMap = data['token'] is Map<String, dynamic>
        ? data['token'] as Map<String, dynamic>
        : data;

    final nextAccessToken = tokenMap['accessToken'] as String?;
    final nextRefreshToken = tokenMap['refreshToken'] as String?;

    if (nextAccessToken != null && nextAccessToken.isNotEmpty) {
      _accessToken = nextAccessToken;
    }

    if (nextRefreshToken != null && nextRefreshToken.isNotEmpty) {
      _refreshToken = nextRefreshToken;
    }
  }

  void _applyAuthHeaders() {
    _dioClient.addOrUpdateHeaders({
      'Authorization': _accessToken != null && _accessToken!.isNotEmpty
          ? 'Bearer $_accessToken'
          : null,
      'x-refresh-token': _refreshToken,
    });
  }

  // String getGameUrl(String gameSlug) {
  //   if (_gameUrlMap.containsKey(gameSlug)) {
  //     return _gameUrlMap[gameSlug]!;
  //   }

  // }

  Map<String, dynamic> getInitGameMessage({
    String? gameSlug,
    required String mode,
    required bool showCloseBtn,
    required double paddingTop,
    required double paddingBottom,
  }) {
    return {
      'type': 'INIT_GAME',
      'mode': mode,
      'gameSlug': gameSlug,
      'accessToken': _accessToken,
      'deviceId': _deviceId,
      'sessionId': _sessionId,
      'showCloseBtn': showCloseBtn,
      'paddingTop': paddingTop,
      "paddingBottom": paddingBottom,
    };
  }

  Map<String, dynamic> getUpdateAccessTokenMessage({
    required String accessToken,
  }) {
    return {'type': 'UPDATE_ACCESS_TOKEN', 'accessToken': accessToken};
  }
}

class QGamiEnvironment {
  static const String production = 'PRODUCTION';
  static const String staging = 'STAGING';
  static const String sandbox = 'SANDBOX';
  static const String development = 'DEVELOPMENT';

  static String getApiBaseUrl(String environment) {
    switch (environment) {
      case staging:
        return 'https://api.qgami.com';
      case sandbox:
        return 'https://api.qgami.com';
      case development:
        return 'https://api-dev.qgami.com';
      case production:
        return 'https://api.qgami.com';
      default:
        return 'https://api-dev.qgami.com';
    }
  }
}

class BaseGameUrl {
  static const String production = 'http://games.qgami.com';
  static const String staging = 'http://games.qgami.com';
  static const String sandbox = 'http://games.qgami.com';
  static const String development = 'http://games-dev.qgami.com';

  static String getBaseUrl(String environment) {
    switch (environment) {
      case QGamiEnvironment.staging:
        return staging;
      case QGamiEnvironment.sandbox:
        return sandbox;
      case QGamiEnvironment.development:
        return development;
      case QGamiEnvironment.production:
        return production;
      default:
        return development;
    }
  }
}
