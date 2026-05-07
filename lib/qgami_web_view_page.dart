import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qgami_sdk/qgami.dart';
import 'package:qgami_sdk/qgami_web_view_event.dart';
import 'package:webview_flutter/webview_flutter.dart';

class QgamiWebViewPage extends StatefulWidget {
  final String initialUrl;
  final ValueChanged<QgamiWebViewEvent>? onWebViewEvent;
  final String? gameSlug;

  const QgamiWebViewPage({
    super.key,
    required this.initialUrl,
    this.onWebViewEvent,
    this.gameSlug,
  });

  @override
  State<QgamiWebViewPage> createState() => _QgamiWebViewPageState();
}

class _QgamiWebViewPageState extends State<QgamiWebViewPage> {
  final WebViewController controller = WebViewController();
  bool _didSendInitGame = false;
  final List<QgamiWebViewEvent> _debugEvents = [];
  bool _showDebugPanel = false;

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
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) async {
            await _installMessageBridge();
          },
          onPageFinished: (String url) async {
            // _initGame();
          },
          onHttpError: (HttpResponseError error) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  void _loadInitialUrl() {
    controller.loadRequest(Uri.parse(widget.initialUrl));
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
        window.dispatchEvent(new MessageEvent('message', { data: payload }));
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
    // AP3A.240905.015.A2
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

  void _initializeJavaScriptChannels() {
    controller.addJavaScriptChannel(
      'QgamiChannel',
      onMessageReceived: (JavaScriptMessage message) {
        try {
          final decoded = jsonDecode(message.message);
          if (decoded is Map<String, dynamic>) {
            final event = QgamiWebViewEvent.fromJson(decoded);
            debugPrint('LOG : QgamiChannel event: $event');
            //_updateAccessToken();

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
              case QgamiWebViewEvent.gameClose:
                break;
              default:
                break;
            }

            setState(() => _debugEvents.add(event));
            widget.onWebViewEvent?.call(event);
            return;
          }

          final event = QgamiWebViewEvent(
            type: 'raw_message',
            data: {'payload': decoded},
          );
          debugPrint('LOG : QgamiChannel raw event: $event');
          setState(() => _debugEvents.add(event));
          widget.onWebViewEvent?.call(event);
        } catch (e) {
          final event = QgamiWebViewEvent(
            type: 'raw_text_message',
            data: {'payload': message.message},
          );
          debugPrint(
            'LOG : QgamiChannel parse fallback: $e, raw=${message.message}',
          );
          setState(() => _debugEvents.add(event));
          widget.onWebViewEvent?.call(event);
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
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
                color: Colors.black.withOpacity(0.85),
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
                          const Text(
                            'Events',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () =>
                                setState(() => _debugEvents.clear()),
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
                      child: _debugEvents.isEmpty
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
                                final e =
                                    _debugEvents[_debugEvents.length -
                                        1 -
                                        index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    '[${_debugEvents.length - index}] ${e.type}${e.data.isNotEmpty ? '  ${e.data}' : ''}',
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                );
                              },
                            ),
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
                    if (_debugEvents.isNotEmpty)
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
                            '${_debugEvents.length}',
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
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
