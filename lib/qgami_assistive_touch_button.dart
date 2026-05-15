import 'package:flutter/material.dart';
import 'package:qgami_sdk/qgami.dart';

class QgamiAssistiveTouchButton extends StatefulWidget {
  final VoidCallback? onTap;
  final VoidCallback? onCloseTap;
  final Widget? child;
  final double size;
  final double horizontalEdgeMargin;
  final double verticalEdgeMargin;
  final bool startFromRightEdge;
  final bool startFromBottomEdge;
  final Duration snapAnimationDuration;
  final Curve snapAnimationCurve;
  final String? gameSlug;
  final bool isClosed;
  final QgamiInitGameMessage? initMessage;

  const QgamiAssistiveTouchButton({
    super.key,
    this.onTap,
    this.onCloseTap,
    this.child,
    this.size = 80,
    this.horizontalEdgeMargin = 16,
    this.verticalEdgeMargin = 16,
    this.startFromRightEdge = true,
    this.startFromBottomEdge = false,
    this.snapAnimationDuration = const Duration(milliseconds: 180),
    this.snapAnimationCurve = Curves.easeOut,
    this.gameSlug,
    this.isClosed = false,
    this.initMessage,
  });

  @override
  State<QgamiAssistiveTouchButton> createState() =>
      _QgamiAssistiveTouchButtonState();
}

class _QgamiAssistiveTouchButtonState extends State<QgamiAssistiveTouchButton> {
  double? _left;
  double? _top;
  bool _isDragging = false;
  bool _hasUserMoved = false;
  double _minLeft = 0;
  double _maxLeft = 0;
  double _minTop = 0;
  double _maxTop = 0;

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
    final ready = await QGami.waitUntilReady();
    if (!ready) {
      return null;
    }

    final url = await QGami.getGameUrl(gameSlug: widget.gameSlug!);
    if (!mounted) {
      return url;
    }
    return url;
  }

  ({double width, double height}) _computeBounds(
    BoxConstraints constraints,
    MediaQueryData mediaQuery,
  ) {
    final width =
        constraints.hasBoundedWidth &&
            constraints.maxWidth.isFinite &&
            constraints.maxWidth > 0
        ? constraints.maxWidth
        : mediaQuery.size.width;
    final height =
        constraints.hasBoundedHeight &&
            constraints.maxHeight.isFinite &&
            constraints.maxHeight > 0
        ? constraints.maxHeight
        : mediaQuery.size.height;

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

    return (width: width, height: height);
  }

  void _initializePositionIfNeeded() {
    if (!_hasUserMoved) {
      _left = widget.startFromRightEdge ? _maxLeft : _minLeft;
      _top = widget.startFromBottomEdge ? _maxTop : _minTop;
      return;
    }

    if (_left != null && _top != null) {
      _left = _left!.clamp(_minLeft, _maxLeft).toDouble();
      _top = _top!.clamp(_minTop, _maxTop).toDouble();
      return;
    }

    _left = widget.startFromRightEdge ? _maxLeft : _minLeft;
    _top = widget.startFromBottomEdge ? _maxTop : _minTop;
  }

  void _snapToNearestHorizontalEdge() {
    final currentLeft = _left ?? _minLeft;
    final distanceToLeft = (currentLeft - _minLeft).abs();
    final distanceToRight = (_maxLeft - currentLeft).abs();
    _left = distanceToLeft <= distanceToRight ? _minLeft : _maxLeft;
  }

  Widget _buildDefaultButton() {
    return Opacity(
      opacity: widget.isClosed ? 0 : 1,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Image.asset(
              'assets/images/img_lucky_spin.png',
              package: 'qgami_sdk',
              width: widget.size - 20,
              height: widget.size - 20,
            ),
          ),
          Positioned(
            top: 8,
            right: 0,
            child: GestureDetector(
              onTap:
                  widget.onCloseTap ??
                  () {
                    setState(() {
                      _hasUserMoved = false;
                      _left = null;
                      _top = null;
                    });
                  },
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              onTap:
                  widget.onCloseTap ??
                  () {
                    setState(() {
                      _hasUserMoved = false;
                      _left = null;
                      _top = null;
                    });
                  },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  "1",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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

        final bounds = _computeBounds(constraints, mediaQuery);
        _initializePositionIfNeeded();

        return SizedBox(
          width: bounds.width,
          height: bounds.height,
          child: Stack(
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
                    QGami.openGame(
                      context,
                      url: url,
                      gameSlug: widget.gameSlug!,
                      initMessage: widget.initMessage,
                    );
                  },
                  onPanStart: (_) {
                    setState(() {
                      _isDragging = true;
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _hasUserMoved = true;
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
          ),
        );
      },
    );
  }
}
