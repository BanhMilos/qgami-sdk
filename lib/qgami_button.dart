import 'package:flutter/material.dart';
import 'package:qgami_sdk/qgami_web_view_event.dart';
import 'package:qgami_sdk/qgami_web_view_page.dart';

class QgamiButton extends StatefulWidget {
  final Widget Function(BuildContext)? customBuilder;
  final String initialUrl;
  final ValueChanged<QgamiWebViewEvent>? onWebViewEvent;
  final bool disabled;

  const QgamiButton({
    super.key,
    this.customBuilder,
    this.initialUrl = 'https://flutter.dev',
    this.onWebViewEvent,
    this.disabled = false,
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
      onTap: widget.disabled
          ? null
          : () {
              try {
                Navigator.of(context).push(
                  PageRouteBuilder<void>(
                    pageBuilder:
                        (
                          BuildContext context,
                          Animation<double> animation,
                          Animation<double> secondaryAnimation,
                        ) {
                          return QgamiWebViewPage(
                            initialUrl: widget.initialUrl,
                            onWebViewEvent: widget.onWebViewEvent,
                            gameSlug: 'slot-machine-qgami',
                          );
                        },
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          const begin = Offset(0.0, 1.0);
                          const end = Offset.zero;
                          const curve = Curves.easeOutCubic;

                          final tween = Tween(
                            begin: begin,
                            end: end,
                          ).chain(CurveTween(curve: curve));
                          return SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          );
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
