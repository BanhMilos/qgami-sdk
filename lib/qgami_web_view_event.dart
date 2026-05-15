class QgamiWebViewEvent {
  static const String initGame = 'INIT_GAME';
  static const String updateAccessToken = 'UPDATE_ACCESS_TOKEN';
  static const String gameReady = 'GAME_READY';
  static const String accessTokenExpired = 'ACCESS_TOKEN_EXPIRED';
  static const String gameLoading = 'GAME_LOADING';
  static const String gameLoaded = 'GAME_LOADED';
  static const String gamePlayStart = 'GAME_PLAY_START';
  static const String gamePlayResult = 'GAME_PLAY_RESULT';
  static const String gamePlayError = 'GAME_PLAY_ERROR';
  static const String gameClose = 'GAME_CLOSE';
  static const String showRewardHistory = 'SHOW_REWARD_HISTORY';
  static const String showMissionCenter = 'SHOW_MISSION_CENTER';

  final String type;
  final Map<String, dynamic> data;

  const QgamiWebViewEvent({required this.type, this.data = const {}});

  factory QgamiWebViewEvent.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return QgamiWebViewEvent(
      type: json['type'] as String? ?? 'unknown',
      data: rawData is Map<String, dynamic>
          ? rawData
          : rawData is Map
          ? Map<String, dynamic>.from(rawData)
          : {},
    );
  }

  @override
  String toString() => 'QgamiWebViewEvent(type: $type, data: $data)';
}
