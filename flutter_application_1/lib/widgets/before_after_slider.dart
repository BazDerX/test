import 'dart:typed_data';

import 'package:flutter/material.dart';

class BeforeAfterSlider extends StatefulWidget {
  const BeforeAfterSlider({
    super.key,
    required this.before,
    required this.after,
  });
  final Uint8List before, after;
  @override
  State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider> {
  double _position = .5;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 342 / 330,
          child: LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              onHorizontalDragUpdate: (details) => setState(() {
                _position = (details.localPosition.dx / constraints.maxWidth)
                    .clamp(0.0, 1.0);
              }),
              onTapDown: (details) => setState(() {
                _position = (details.localPosition.dx / constraints.maxWidth)
                    .clamp(0.0, 1.0);
              }),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(widget.after, fit: BoxFit.cover),
                  ClipRect(
                    clipper: _ComparisonClipper(_position),
                    child: Image.memory(widget.before, fit: BoxFit.cover),
                  ),
                  Positioned(
                    left: constraints.maxWidth * _position - 1,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 2, color: Colors.white),
                  ),
                  Positioned(
                    left: (constraints.maxWidth * _position - 18).clamp(
                      0.0,
                      constraints.maxWidth - 36,
                    ),
                    top: constraints.maxHeight / 2 - 18,
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.code,
                        color: Color(0xFF315C47),
                        size: 20,
                      ),
                    ),
                  ),
                  const Positioned(top: 10, left: 10, child: _Label('Өмнө')),
                  const Positioned(top: 10, right: 10, child: _Label('Дараа')),
                ],
              ),
            ),
          ),
        ),
      ),
      // Retain a keyboard and screen-reader accessible comparison control.
      SizedBox(
        height: 24,
        child: Slider(
          value: _position,
          onChanged: (value) => setState(() => _position = value),
          semanticFormatterCallback: (value) =>
              'Өмнөх зураг ${(value * 100).round()} хувь',
        ),
      ),
    ],
  );
}

class _ComparisonClipper extends CustomClipper<Rect> {
  _ComparisonClipper(this.position);
  final double position;
  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * position, size.height);
  @override
  bool shouldReclip(covariant _ComparisonClipper oldClipper) =>
      oldClipper.position != position;
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: Color(0xFF27312C)),
      ),
    ),
  );
}
