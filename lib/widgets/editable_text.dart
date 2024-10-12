import 'package:flutter/material.dart';
import 'dart:math' as math;

class CustomEditableText {
  String text;
  Offset position;
  Color color;
  double fontSize;
  double rotation;
  String fontFamily;
  bool hasShadow;

  CustomEditableText({
    required this.text,
    required this.position,
    required this.color,
    required this.fontSize,
    required this.rotation,
    this.fontFamily = 'aammufkF',
    this.hasShadow = false, // Changed from true to false
  });
}

class EditableTextWidget extends StatefulWidget {
  final CustomEditableText text;
  final Function(EditableTextWidget) onSelect;
  final VoidCallback onEdit;
  final Function(CustomEditableText) onUpdate;
  final bool isActive;

  const EditableTextWidget({
    super.key,
    required this.text,
    required this.onSelect,
    required this.onEdit,
    required this.onUpdate,
    required this.isActive,
  });

  @override
  State<EditableTextWidget> createState() => _EditableTextWidgetState();
}

class _EditableTextWidgetState extends State<EditableTextWidget> {
  late CustomEditableText _text;
  double _baseScaleFactor = 1.0;
  double _baseRotation = 0.0;
  late Size _textSize;
  Offset _lastFocalPoint = Offset.zero;
  final double _minTouchAreaPadding = 20.0;
  bool _isDragging = false;
  static const double _snapAngle = math.pi / 2; // 90 degrees in radians
  static const double _snapThreshold = math.pi / 36; // 5 degrees in radians
  static const int _minCharacters = 8;

  @override
  void initState() {
    super.initState();
    _text = widget.text;
    _updateTextSize();
  }

  void _updateTextSize() {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: _text.text,
        style: TextStyle(
          fontSize: _text.fontSize,
          fontFamily: _text.fontFamily,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);

    // Calculate the minimum width for 8 characters
    final minWidthPainter = TextPainter(
      text: TextSpan(
        text: 'X' * _minCharacters,
        style: TextStyle(
          fontSize: _text.fontSize,
          fontFamily: _text.fontFamily,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);

    // Use the larger of the two widths
    _textSize = Size(
      math.max(textPainter.width, minWidthPainter.width),
      textPainter.height,
    );
  }

  void _updateText() {
    widget.onUpdate(_text);
    _updateTextSize();
  }

  double _softSnapRotation(double rotation) {
    double normalizedRotation = rotation % (2 * math.pi);
    if (normalizedRotation < 0) normalizedRotation += 2 * math.pi;

    for (int i = 0; i < 4; i++) {
      double target = i * _snapAngle;
      if ((normalizedRotation - target).abs() < _snapThreshold) {
        return target;
      }
    }
    return normalizedRotation;
  }

  void _handleTap() {
    if (widget.isActive) {
      // If already active, open edit dialog
      widget.onEdit();
    } else {
      // If not active, select this text
      widget.onSelect(widget);
    }
  }

  void _handleInteraction() {
    if (!widget.isActive) {
      widget.onSelect(widget);
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding =
        math.max(_minTouchAreaPadding, _textSize.width * 0.1);

    return Positioned(
      left: _text.position.dx - horizontalPadding,
      top: _text.position.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _isDragging = false,
        onTapUp: (_) {
          if (!_isDragging) {
            _handleTap();
          }
        },
        onScaleStart: (details) {
          _isDragging = true;
          _baseScaleFactor = _text.fontSize / 20;
          _baseRotation = _text.rotation;
          _lastFocalPoint = details.focalPoint;
          _handleInteraction();
        },
        onScaleUpdate: (details) {
          setState(() {
            if (details.pointerCount == 1) {
              // Handle dragging
              final delta = details.focalPoint - _lastFocalPoint;
              _text.position += delta;
            } else if (details.pointerCount == 2) {
              // Handle scaling and rotation
              final newFontSize = 20 * _baseScaleFactor * details.scale;
              final sizeDiff = newFontSize - _text.fontSize;

              final focalPointDelta = details.focalPoint - _lastFocalPoint;
              final centerX = _text.position.dx + _textSize.width / 2;
              final centerY = _text.position.dy + _textSize.height / 2;

              _text.position = Offset(
                centerX -
                    (_textSize.width + sizeDiff) / 2 +
                    focalPointDelta.dx / 2,
                centerY -
                    (_textSize.height + sizeDiff) / 2 +
                    focalPointDelta.dy / 2,
              );

              _text.fontSize = newFontSize;
              // Apply soft snap to rotation
              _text.rotation =
                  _softSnapRotation(_baseRotation + details.rotation);
            }
            _lastFocalPoint = details.focalPoint;
            _updateText();
          });
        },
        onScaleEnd: (_) {
          _isDragging = false;
        },
        child: Transform.rotate(
          angle: _text.rotation,
          child: Container(
            width: _textSize.width + horizontalPadding * 2,
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 0,
            ),
            decoration: BoxDecoration(
              border: widget.isActive
                  ? Border.all(color: Colors.blue, width: 2)
                  : Border.all(color: Colors.transparent, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _text.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _text.color,
                fontSize: _text.fontSize,
                fontFamily: _text.fontFamily,
                shadows: _text.hasShadow
                    ? [
                        Shadow(
                          blurRadius: 5.0,
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(1.0, 1.0),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
