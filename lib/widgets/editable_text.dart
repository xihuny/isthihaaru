import 'package:flutter/material.dart';
import 'dart:math' as math;

class CustomEditableText {
  String text;
  Offset position;
  Color color;
  double fontSize;
  double rotation;
  String fontFamily;

  CustomEditableText({
    required this.text,
    required this.position,
    required this.color,
    required this.fontSize,
    required this.rotation,
    this.fontFamily = 'aammufkF',
  });
}

class EditableTextWidget extends StatefulWidget {
  final CustomEditableText text;
  final VoidCallback onTap;
  final Function(CustomEditableText) onUpdate;
  final bool isActive;

  const EditableTextWidget({
    super.key,
    required this.text,
    required this.onTap,
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
          fontFamily: 'MVAWaheed',
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    _textSize = textPainter.size;
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

  @override
  Widget build(BuildContext context) {
    final horizontalPadding =
        math.max(_minTouchAreaPadding, _textSize.width * 0.2);

    return Positioned(
      left: _text.position.dx - horizontalPadding,
      top: _text.position.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _isDragging = false,
        onTapUp: (_) {
          if (!_isDragging) {
            widget.onTap();
          }
        },
        onScaleStart: (details) {
          _isDragging = true;
          _baseScaleFactor = _text.fontSize / 20;
          _baseRotation = _text.rotation;
          _lastFocalPoint = details.focalPoint;
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
