import 'package:flutter/material.dart';
import 'package:qgami_sdk/qgami_core.dart';

export 'qgami_button.dart';
export 'qgami_assistive_touch_button.dart';

class QGami {
  static bool get isInitialized => QGamiCore.instance.isInitialized;
  static bool get isIdentified => QGamiCore.instance.isIdentified;
  static bool get isReady => QGamiCore.instance.isReady;

  static Future<void> initialize({
    required String apiKey,
    required String environment,
    required String locale,
  }) async {
    await QGamiCore.instance.initialize(
      apiKey: apiKey,
      environment: environment,
      locale: locale,
    );
  }

  static Future<bool> identify({
    required String email,
    required String username,
    required String userId,
  }) async {
    return await QGamiCore.instance.identify(
      email: email,
      username: username,
      userId: userId,
    );
  }

  static void openGame(
    BuildContext context, {
    required String? url,
    required String gameSlug,
  }) {
    QGamiCore.instance.openGame(context, url: url, gameSlug: gameSlug);
  }

  static void showFloatingGameWidget() {
    QGamiCore.instance.showFloatingWidget();
  }

  static void openHub() {
    QGamiCore.instance.openHub();
  }

  static Future<String?> getGameUrl({required String gameSlug}) {
    return QGamiCore.instance.getGameUrl(gameSlug: gameSlug);
  }

  static Future<bool> waitUntilReady({
    Duration timeout = const Duration(seconds: 2),
  }) {
    return QGamiCore.instance.waitUntilReady(timeout: timeout);
  }

  static Map<String, dynamic> getInitGameMessage({
    String? gameSlug,
    required String mode,
    required bool showCloseBtn,
    required double paddingTop,
    required double paddingBottom,
  }) {
    return QGamiCore.instance.getInitGameMessage(
      gameSlug: gameSlug,
      mode: mode,
      showCloseBtn: showCloseBtn,
      paddingTop: paddingTop,
      paddingBottom: paddingBottom,
    );
  }

  static Future<String?> refreshAccessToken() {
    return QGamiCore.instance.refreshAccessToken();
  }

  static Map<String, dynamic> getUpdateAccessTokenMessage({
    required String accessToken,
  }) {
    return QGamiCore.instance.getUpdateAccessTokenMessage(
      accessToken: accessToken,
    );
  }
}
