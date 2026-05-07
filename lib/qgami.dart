import 'package:qgami_sdk/qgami_core.dart';

export 'qgami_button.dart';

class QGami {
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

  static void openGame() {
    QGamiCore.instance.openGame();
  }

  static void showFloatingGameWidget() {
    QGamiCore.instance.showFloatingWidget();
  }

  static void openHub() {
    QGamiCore.instance.openHub();
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
