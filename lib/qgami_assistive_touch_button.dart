import 'package:flutter/material.dart';
import 'package:qgami_sdk/qgami.dart';

class QgamiAssistiveTouchButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget? child;
  final double size;
  final double horizontalEdgeMargin;
  final double verticalEdgeMargin;
  final double initialYPosition;
  final bool startFromRightEdge;
  final Duration snapAnimationDuration;
  final Curve snapAnimationCurve;
  final String? gameSlug;

  const QgamiAssistiveTouchButton({
    super.key,
    this.onTap,
    this.child,
    this.size = 56,
    this.horizontalEdgeMargin = 16,
    this.verticalEdgeMargin = 16,
    this.initialYPosition = 160,
    this.startFromRightEdge = true,
    this.snapAnimationDuration = const Duration(milliseconds: 180),
    this.snapAnimationCurve = Curves.easeOut,
    this.gameSlug,
  });

  @override
  State<QgamiAssistiveTouchButton> createState() =>
      _QgamiAssistiveTouchButtonState();
}

class _QgamiAssistiveTouchButtonState extends State<QgamiAssistiveTouchButton> {
  double? _left;
  double? _top;
  bool _isDragging = false;

  double _minLeft = 0;
  double _maxLeft = 0;
  double _minTop = 0;
  double _maxTop = 0;
  String? _playUrl;

  @override
  void initState() {
    super.initState();
    _preloadPlayUrlIfPossible();
  }

  @override
  void didUpdateWidget(covariant QgamiAssistiveTouchButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final slugChanged = oldWidget.gameSlug != widget.gameSlug;
    if (slugChanged) {
      _playUrl = null;
    }
    if (slugChanged) {
      _preloadPlayUrlIfPossible();
    }
  }

  Future<void> _preloadPlayUrlIfPossible() async {
    await _ensurePlayUrl();
  }

  Future<String?> _ensurePlayUrl() async {
    if (widget.gameSlug == null) {
      return null;
    }
    if (_playUrl != null && _playUrl!.isNotEmpty) {
      return _playUrl;
    }

    final ready = await QGami.waitUntilReady();
    if (!ready) {
      return null;
    }

    final url = await QGami.getGameUrl(gameSlug: widget.gameSlug!);
    if (!mounted) {
      return url;
    }
    setState(() => _playUrl = url);
    return url;
  }

  void _computeBounds(BoxConstraints constraints, MediaQueryData mediaQuery) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;

    _minLeft = widget.horizontalEdgeMargin;
    _maxLeft = width - widget.size - widget.horizontalEdgeMargin;

    _minTop = mediaQuery.padding.top + widget.verticalEdgeMargin;
    _maxTop =
        height -
        widget.size -
        mediaQuery.padding.bottom -
        widget.verticalEdgeMargin;

    if (_maxLeft < _minLeft) {
      _maxLeft = _minLeft;
    }
    if (_maxTop < _minTop) {
      _maxTop = _minTop;
    }
  }

  void _initializePositionIfNeeded() {
    if (_left != null && _top != null) {
      _left = _left!.clamp(_minLeft, _maxLeft).toDouble();
      _top = _top!.clamp(_minTop, _maxTop).toDouble();
      return;
    }

    _left = widget.startFromRightEdge ? _maxLeft : _minLeft;
    _top = widget.initialYPosition.clamp(_minTop, _maxTop).toDouble();
  }

  void _snapToNearestHorizontalEdge() {
    final currentLeft = _left ?? _minLeft;
    final distanceToLeft = (currentLeft - _minLeft).abs();
    final distanceToRight = (_maxLeft - currentLeft).abs();
    _left = distanceToLeft <= distanceToRight ? _minLeft : _maxLeft;
  }

  Widget _buildDefaultButton() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(Icons.touch_app, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // This widget needs bounded parent constraints so drag limits can be computed.
        assert(
          constraints.hasBoundedHeight && constraints.hasBoundedWidth,
          'QgamiAssistiveTouchButton requires bounded width and height. '
          'Wrap it in a SizedBox/Stack with finite constraints.',
        );

        _computeBounds(constraints, mediaQuery);
        _initializePositionIfNeeded();

        return Stack(
          children: [
            AnimatedPositioned(
              duration: _isDragging
                  ? Duration.zero
                  : widget.snapAnimationDuration,
              curve: widget.snapAnimationCurve,
              left: _left,
              top: _top,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  if (widget.onTap != null) {
                    widget.onTap!();
                    return;
                  }
                  final url = await _ensurePlayUrl();
                  if (!context.mounted || widget.gameSlug == null) {
                    return;
                  }
                  QGami.openGame(context, url: url, gameSlug: widget.gameSlug!);
                },
                onPanStart: (_) {
                  setState(() {
                    _isDragging = true;
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _left = (_left! + details.delta.dx)
                        .clamp(_minLeft, _maxLeft)
                        .toDouble();
                    _top = (_top! + details.delta.dy)
                        .clamp(_minTop, _maxTop)
                        .toDouble();
                  });
                },
                onPanEnd: (_) {
                  setState(() {
                    _isDragging = false;
                    _snapToNearestHorizontalEdge();
                  });
                },
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: widget.child ?? _buildDefaultButton(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
