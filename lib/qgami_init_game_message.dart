class QgamiInitGameMessage {
  final String type;
  final String mode;
  final String? gameSlug;
  final String? accessToken;
  final String? deviceId;
  final String? sessionId;
  final bool showCloseBtn;
  final bool showRewardHistoryBtn;
  final double paddingTop;
  final double paddingBottom;

  const QgamiInitGameMessage({
    this.type = 'INIT_GAME',
    required this.mode,
    required this.gameSlug,
    required this.accessToken,
    required this.deviceId,
    required this.sessionId,
    required this.showCloseBtn,
    required this.showRewardHistoryBtn,
    required this.paddingTop,
    required this.paddingBottom,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'mode': mode,
      'gameSlug': gameSlug,
      'accessToken': accessToken,
      'deviceId': deviceId,
      'sessionId': sessionId,
      'showCloseBtn': showCloseBtn,
      'showRewardHistoryBtn': showRewardHistoryBtn,
      'paddingTop': paddingTop,
      'paddingBottom': paddingBottom,
    };
  }
}
