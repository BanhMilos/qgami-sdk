import 'package:flutter/material.dart';
import 'package:qgami_sdk/qgami.dart';
import 'package:qgami_sdk/qgami_web_view_event.dart';
import 'package:qgami_sdk/qgami_web_view_page.dart';

class QgamiButton extends StatefulWidget {
  final Widget Function(BuildContext)? customBuilder;
  final String gameSlug;
  final ValueChanged<QgamiWebViewEvent>? onWebViewEvent;
  final bool disabled;

  const QgamiButton({
    super.key,
    this.customBuilder,
    required this.gameSlug,
    this.onWebViewEvent,
    this.disabled = false,
  });

  @override
  State<QgamiButton> createState() => _QgamiButtonState();
}

class _QgamiButtonState extends State<QgamiButton> {
  String? _url;

  @override
  void initState() {
    super.initState();
    _preloadPlayUrlIfPossible();
  }

  @override
  void didUpdateWidget(covariant QgamiButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final slugChanged = oldWidget.gameSlug != widget.gameSlug;
    final becameEnabled = oldWidget.disabled && !widget.disabled;
    if (slugChanged) {
      _url = null;
    }
    if (slugChanged || becameEnabled) {
      _preloadPlayUrlIfPossible();
    }
  }

  Future<void> _preloadPlayUrlIfPossible() async {
    if (widget.disabled) {
      return;
    }
    await _ensurePlayUrl();
  }

  Future<String?> _ensurePlayUrl() async {
    if (_url != null && _url!.isNotEmpty) {
      return _url;
    }

    final ready = await QGami.waitUntilReady();
    if (!ready) {
      return null;
    }

    final url = await QGami.getGameUrl(gameSlug: widget.gameSlug);
    if (!mounted) {
      return url;
    }
    setState(() => _url = url);
    return url;
  }

  Widget _buildButton(BuildContext context) {
    if (widget.customBuilder == null) {
      return Container(
        color: Colors.green,
        child: const Text('Default Qgami Button'),
      );
    }
    return widget.customBuilder!(context);
  }

  void _openGamePage(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) {
              return QgamiWebViewPage(
                onWebViewEvent: widget.onWebViewEvent,
                gameSlug: widget.gameSlug,
                url: _url ?? '',
              );
            },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
  }

  Future<void> _handleTap(BuildContext context) async {
    final url = await _ensurePlayUrl();
    if (!context.mounted) {
      return;
    }
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Game URL is not ready. Please wait for identify.'),
        ),
      );
      return;
    }

    try {
      _openGamePage(context);
    } on AssertionError catch (error) {
      debugPrint(
        'QgamiButton: WebView is unavailable on this platform: $error',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.disabled ? null : () async => _handleTap(context),
      child: _buildButton(context),
    );
  }
}
