import 'dart:async';

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
  String _environment = QGamiEnvironment.development;
  bool _isInitialized = false;
  bool _isIdentified = false;
  Completer<void>? _readyCompleter;
  Future<bool>? _identifyInFlight;

  QGamiCore._();
  final Map<String, String> _gameUrlMap = {};

  bool get isInitialized => _isInitialized;
  bool get isIdentified => _isIdentified;
  bool get isReady => _isInitialized && _isIdentified;

  Future<void> initialize({
    required String apiKey,
    required String environment,
    required String locale,
  }) async {
    _apiKey = apiKey;
    _environment = environment;
    _dioClient.setBaseUrl(
      '${QGamiEnvironment.getApiBaseUrl(_environment)}/$_apiVersion$_basePath',
    );
    final deviceId = await _getDeviceId();
    _deviceId = deviceId;
    _dioClient.setDefaultHeaders({'x-device-id': deviceId});

    _isInitialized = true;
    _isIdentified = false;
    _identifyInFlight = null;
    _readyCompleter = Completer<void>();
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
    if (!_isInitialized) {
      debugPrint('LOG : identify skipped: SDK not initialized yet.');
      return false;
    }

    final inFlight = _identifyInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final future = _identifyInternal(
      email: email,
      username: username,
      userId: userId,
    );
    _identifyInFlight = future;
    final result = await future;
    _identifyInFlight = null;
    return result;
  }

  Future<bool> _identifyInternal({
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
        _dioClient.addOrUpdateHeaders({'x-session-id': _sessionId});
        _setTokensFromResponseData(data);
        _applyAuthHeaders();
        _isIdentified = true;
        final completer = _readyCompleter;
        if (completer != null && !completer.isCompleted) {
          completer.complete();
        }
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

  Future<bool> waitUntilReady({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (isReady) {
      return true;
    }

    final completer = _readyCompleter ??= Completer<void>();
    try {
      await completer.future.timeout(timeout);
      return true;
    } catch (_) {
      return false;
    }
  }

  void openGame() {}

  void showFloatingWidget() {}

  void openHub() {}

  Future<String?> getGameUrl({required String gameSlug}) async {
    if (_gameUrlMap.containsKey(gameSlug)) {
      debugPrint(
        'LOG : Game URL for $gameSlug already cached: ${_gameUrlMap[gameSlug]}',
      );
      return _gameUrlMap[gameSlug];
    }
    try {
      final response = await _dioClient.get('/games/$gameSlug');
      final responseData = response.data;
      if (responseData['success'] == true) {
        final data = responseData['data'];
        final gameData = data['game'];
        final playUrl = gameData['playUrl'] as String?;
        if (playUrl != null && playUrl.isNotEmpty) {
          _gameUrlMap[gameSlug] =
              '${QGamiEnvironment.getWebViewBaseUrl(_environment)}/$playUrl';
          debugPrint('LOG : Fetched game URL for $gameSlug: $playUrl');
        } else {
          debugPrint('LOG : Game URL not found in response for $gameSlug');
        }
      } else {
        debugPrint(
          'LOG : Failed to fetch game URL for $gameSlug: ${responseData['message']}',
        );
      }
    } catch (e) {
      debugPrint('LOG : Error fetching game URL for $gameSlug: $e');
    }
    return _gameUrlMap[gameSlug];
  }

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

  static String getWebViewBaseUrl(String environment) {
    switch (environment) {
      case staging:
        return 'https://games.qgami.com';
      case sandbox:
        return 'https://games.qgami.com';
      case development:
        return 'https://games-dev.qgami.com';
      case production:
        return 'https://games.qgami.com';
      default:
        return 'https://games-dev.qgami.com';
    }
  }
}
