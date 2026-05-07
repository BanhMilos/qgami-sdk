import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qgami_sdk/qgami.dart';
import 'package:qgami_sdk/qgami_web_view_event.dart';
import 'package:webview_flutter/webview_flutter.dart';

class QgamiWebViewPage extends StatefulWidget {
  final ValueChanged<QgamiWebViewEvent>? onWebViewEvent;
  final String gameSlug;
  final String url;

  const QgamiWebViewPage({
    super.key,
    this.onWebViewEvent,
    required this.gameSlug,
    required this.url,
  });

  @override
  State<QgamiWebViewPage> createState() => _QgamiWebViewPageState();
}

class _QgamiWebViewPageState extends State<QgamiWebViewPage> {
  static const int _maxDebugEvents = 200;

  final WebViewController controller = WebViewController();
  bool _didSendInitGame = false;
  final List<QgamiWebViewEvent> _debugEvents = [];
  final List<({JavaScriptLogLevel level, String message})> _consoleLogs = [];
  bool _showDebugPanel = false;
  int _debugTab = 0; // 0 = Events, 1 = Console

  @override
  void initState() {
    super.initState();
    _initializeJavaScriptChannels();
    _setupController();
    _loadInitialUrl();
  }

  void _setupController() {
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) async {
            await _installMessageBridge();
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..setOnConsoleMessage((JavaScriptConsoleMessage msg) {
        setState(() {
          if (_consoleLogs.length >= _maxDebugEvents) _consoleLogs.removeAt(0);
          _consoleLogs.add((level: msg.level, message: msg.message));
        });
      });
  }

  void _loadInitialUrl() async {
    final playUrl = widget.url;
    final uri = Uri.tryParse(playUrl);
    if (uri == null) {
      debugPrint('LOG : Qgami invalid play URL: $playUrl');
      return;
    }

    controller.loadRequest(uri);
  }

  Future<void> _installMessageBridge() async {
    try {
      await controller.runJavaScript('''
        (function () {
          if (window.__qgamiBridgeInstalled) return;
          window.__qgamiBridgeInstalled = true;

          function forwardToFlutter(payload) {
            try {
              var message = payload;
              if (typeof payload !== 'string') {
                message = JSON.stringify(payload);
              }

              if (typeof QgamiChannel !== 'undefined' && typeof QgamiChannel.postMessage === 'function') {
                QgamiChannel.postMessage(message);
              } else if (typeof window.QgamiChannel !== 'undefined' && typeof window.QgamiChannel.postMessage === 'function') {
                window.QgamiChannel.postMessage(message);
              }
            } catch (_) {}
          }

          window.addEventListener('message', function (event) {
            forwardToFlutter(event.data);
          });

          window.qgamiPostToFlutter = forwardToFlutter;
        })();
      ''');
      debugPrint('LOG : Qgami bridge installed');
    } catch (e) {
      debugPrint('LOG : Qgami bridge install failed: $e');
    }
  }

  Future<void> _sendMessageToWeb(Map<String, dynamic> message) async {
    final encodedMessage = jsonEncode(message);

    await controller.runJavaScript('''
      (function () {
        const payload = $encodedMessage;

        if (typeof window.onQgamiMessage === 'function') {
          window.onQgamiMessage(payload);
        }

        window.postMessage(payload, '*');
      })();
    ''');
  }

  Future<void> _initGame() async {
    final message = QGami.getInitGameMessage(
      gameSlug: widget.gameSlug,
      mode: 'REMOTE',
      showCloseBtn: true,
      paddingTop: MediaQuery.of(context).padding.top,
      paddingBottom: MediaQuery.of(context).padding.bottom,
    );
    try {
      await _sendMessageToWeb(message);
      debugPrint('LOG : Qgami INIT_GAME sent $message');
    } catch (e) {
      debugPrint('LOG : Qgami INIT_GAME send failed: $e');
    }
  }

  Future<void> _updateAccessToken() async {
    final accessToken = await QGami.refreshAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      debugPrint('LOG : Qgami UPDATE_ACCESS_TOKEN skipped: empty token');
      return;
    }

    final message = QGami.getUpdateAccessTokenMessage(accessToken: accessToken);

    try {
      await _sendMessageToWeb(message);
      debugPrint('LOG : Qgami UPDATE_ACCESS_TOKEN sent');
    } catch (e) {
      debugPrint('LOG : Qgami UPDATE_ACCESS_TOKEN send failed: $e');
    }
  }

  void _recordEvent(QgamiWebViewEvent event) {
    if (_debugEvents.length >= _maxDebugEvents) {
      _debugEvents.removeAt(0);
    }
    _debugEvents.add(event);
    setState(() {});
    widget.onWebViewEvent?.call(event);
  }

  void _handleStructuredEvent(QgamiWebViewEvent event) {
    switch (event.type) {
      case QgamiWebViewEvent.gameReady:
        if (!_didSendInitGame) {
          _didSendInitGame = true;
          _initGame();
        }
        break;
      case QgamiWebViewEvent.accessTokenExpired:
        _updateAccessToken();
        break;
      case QgamiWebViewEvent.gameLoading:
      case QgamiWebViewEvent.gameLoaded:
      case QgamiWebViewEvent.gamePlayStart:
      case QgamiWebViewEvent.gamePlayResult:
      case QgamiWebViewEvent.gamePlayError:
        break;
      case QgamiWebViewEvent.gameClose:
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        break;
      default:
        break;
    }
  }

  void _initializeJavaScriptChannels() {
    controller.addJavaScriptChannel(
      'QgamiChannel',
      onMessageReceived: (JavaScriptMessage message) {
        try {
          final decoded = jsonDecode(message.message);
          if (decoded is Map) {
            final event = QgamiWebViewEvent.fromJson(
              Map<String, dynamic>.from(decoded),
            );
            debugPrint('LOG : QgamiChannel event: $event');
            _handleStructuredEvent(event);
            _recordEvent(event);
            return;
          }

          final event = QgamiWebViewEvent(
            type: 'raw_message',
            data: {'payload': decoded},
          );
          debugPrint('LOG : QgamiChannel raw event: $event');
          _recordEvent(event);
        } catch (e) {
          final event = QgamiWebViewEvent(
            type: 'raw_text_message',
            data: {'payload': message.message},
          );
          debugPrint(
            'LOG : QgamiChannel parse fallback: $e, raw=${message.message}',
          );
          _recordEvent(event);
        }
      },
    );
  }

  static Color _consoleColor(JavaScriptLogLevel level) {
    switch (level) {
      case JavaScriptLogLevel.error:
        return Colors.redAccent;
      case JavaScriptLogLevel.warning:
        return Colors.orangeAccent;
      case JavaScriptLogLevel.debug:
        return Colors.blueAccent;
      case JavaScriptLogLevel.info:
        return Colors.cyanAccent;
      default:
        return Colors.greenAccent;
    }
  }

  static String _consolePrefix(JavaScriptLogLevel level) {
    switch (level) {
      case JavaScriptLogLevel.error:
        return '[ERR]';
      case JavaScriptLogLevel.warning:
        return '[WRN]';
      case JavaScriptLogLevel.debug:
        return '[DBG]';
      case JavaScriptLogLevel.info:
        return '[INF]';
      default:
        return '[LOG]';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (_showDebugPanel)
            Positioned(
              top: 80,
              left: 8,
              right: 8,
              bottom: 80,
              child: Material(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          _TabButton(
                            label: 'Events',
                            active: _debugTab == 0,
                            onTap: () => setState(() => _debugTab = 0),
                          ),
                          const SizedBox(width: 8),
                          _TabButton(
                            label: 'Console',
                            active: _debugTab == 1,
                            onTap: () => setState(() => _debugTab = 1),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => setState(() {
                              if (_debugTab == 0) {
                                _debugEvents.clear();
                              } else {
                                _consoleLogs.clear();
                              }
                            }),
                            child: const Text(
                              'Clear',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    Expanded(
                      child: _debugTab == 0
                          ? (_debugEvents.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No events yet',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(8),
                                    itemCount: _debugEvents.length,
                                    itemBuilder: (context, index) {
                                      final e = _debugEvents[index];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 2,
                                        ),
                                        child: Text(
                                          '[${index + 1}] ${e.type}${e.data.isNotEmpty ? '  ${e.data}' : ''}',
                                          style: const TextStyle(
                                            color: Colors.greenAccent,
                                            fontSize: 11,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      );
                                    },
                                  ))
                          : (_consoleLogs.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No console output yet',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(8),
                                    itemCount: _consoleLogs.length,
                                    itemBuilder: (context, index) {
                                      final log = _consoleLogs[index];
                                      final color = _consoleColor(log.level);
                                      final prefix = _consolePrefix(log.level);
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 2,
                                        ),
                                        child: Text(
                                          '$prefix ${log.message}',
                                          style: TextStyle(
                                            color: color,
                                            fontSize: 11,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      );
                                    },
                                  )),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 40,
            right: 20,
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: Icon(
                        _showDebugPanel
                            ? Icons.bug_report
                            : Icons.bug_report_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () =>
                          setState(() => _showDebugPanel = !_showDebugPanel),
                    ),
                    if (_debugEvents.isNotEmpty || _consoleLogs.isNotEmpty)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${_debugEvents.length + _consoleLogs.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? Colors.white24 : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white54,
            fontSize: 12,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
