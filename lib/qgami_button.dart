import 'package:flutter/material.dart';
import 'package:qgami_sdk/qgami.dart';
import 'package:qgami_sdk/qgami_web_view_event.dart';

class QgamiButton extends StatefulWidget {
  final Widget Function(BuildContext)? customBuilder;
  final String gameSlug;
  final ValueChanged<QgamiWebViewEvent>? onWebViewEvent;
  final bool disabled;
  final QgamiInitGameMessage? initMessage;

  const QgamiButton({
    super.key,
    this.customBuilder,
    required this.gameSlug,
    this.onWebViewEvent,
    this.disabled = false,
    this.initMessage,
  });

  @override
  State<QgamiButton> createState() => _QgamiButtonState();
}

class _QgamiButtonState extends State<QgamiButton> {
  String? _playUrl;

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
      _playUrl = null;
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
    if (_playUrl != null && _playUrl!.isNotEmpty) {
      return _playUrl;
    }

    final ready = await QGami.waitUntilReady();
    if (!ready) {
      return null;
    }

    final url = await QGami.getGameUrl(gameSlug: widget.gameSlug);
    if (!mounted) {
      return url;
    }
    setState(() => _playUrl = url);
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

  Future<void> _handleTap(
    BuildContext context, {
    QgamiInitGameMessage? initMessage,
  }) async {
    final url = await _ensurePlayUrl();
    if (!context.mounted) {
      return;
    }
    QGami.openGame(
      context,
      url: url,
      gameSlug: widget.gameSlug,
      initMessage: initMessage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.disabled
          ? null
          : () async => _handleTap(context, initMessage: widget.initMessage),
      child: _buildButton(context),
    );
  }
}
