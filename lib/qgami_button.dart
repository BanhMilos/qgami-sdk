import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class QgamiButton extends StatefulWidget {
  final Widget Function(BuildContext)? customBuilder;
  final String initialUrl;

  const QgamiButton({
    super.key,
    this.customBuilder,
    this.initialUrl = 'https://flutter.dev',
  });

  @override
  State<QgamiButton> createState() => _QgamiButtonState();
}

class _QgamiButtonState extends State<QgamiButton> {
  Widget _buildButton(BuildContext context) {
    if (widget.customBuilder == null) {
      return Container(
        color: Colors.green,
        child: Text('Default Qgami Button'),
      );
    }
    return widget.customBuilder!(context);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        try {
          final controller = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setNavigationDelegate(
              NavigationDelegate(
                onProgress: (int progress) {
                  // Update loading bar.
                },
                onPageStarted: (String url) {},
                onPageFinished: (String url) {},
                onHttpError: (HttpResponseError error) {},
                onWebResourceError: (WebResourceError error) {},
                onNavigationRequest: (NavigationRequest request) {
                  if (request.url.startsWith('https://www.youtube.com/')) {
                    return NavigationDecision.prevent;
                  }
                  return NavigationDecision.navigate;
                },
              ),
            )
            ..loadRequest(Uri.parse(widget.initialUrl));

          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext context) {
                return _QgamiWebViewPage(controller: controller);
              },
            ),
          );
        } on AssertionError catch (error) {
          debugPrint(
            'QgamiButton: WebView is unavailable on this platform: $error',
          );
        }
      },
      child: _buildButton(context),
    );
  }
}

class _QgamiWebViewPage extends StatelessWidget {
  final WebViewController controller;

  const _QgamiWebViewPage({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
