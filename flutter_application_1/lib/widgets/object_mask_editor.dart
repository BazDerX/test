import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/room_design_project.dart';
import '../services/room_image_service.dart';

enum MaskTool { point, box, brush, erase }

class ImageCoverTransform {
  ImageCoverTransform(this.imageSize, this.viewport) {
    final fit = applyBoxFit(BoxFit.cover, imageSize, viewport);
    source = Alignment.center.inscribe(fit.source, Offset.zero & imageSize);
    destination = Alignment.center.inscribe(
      fit.destination,
      Offset.zero & viewport,
    );
  }
  final Size imageSize, viewport;
  late final Rect source, destination;
  Offset toImage(Offset point) => Offset(
    (source.left +
            (point.dx - destination.left) * source.width / destination.width)
        .clamp(0, imageSize.width - 1),
    (source.top +
            (point.dy - destination.top) * source.height / destination.height)
        .clamp(0, imageSize.height - 1),
  );
}

class MaskStroke {
  MaskStroke({required this.erase, required this.width, required this.points});
  final bool erase;
  final double width;
  final List<Offset> points;
}

class ObjectMaskEditorController extends ChangeNotifier {
  ui.Image? baseMask;
  final List<MaskStroke> strokes = [];
  Rect? box;
  Size imageSize = Size.zero;
  void clear() {
    baseMask?.dispose();
    baseMask = null;
    strokes.clear();
    box = null;
    notifyListeners();
  }

  void undo() {
    if (strokes.isNotEmpty) strokes.removeLast();
    box = null;
    notifyListeners();
  }

  void changed() => notifyListeners();
  Future<void> loadBase(List<int> png) async {
    clear();
    final codec = await ui.instantiateImageCodec(Uint8List.fromList(png));
    try {
      final frame = await codec.getNextFrame();
      baseMask = frame.image;
      imageSize = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
    } finally {
      codec.dispose();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    baseMask?.dispose();
    super.dispose();
  }

  Future<ui.Image> renderMask() async {
    if (imageSize.isEmpty) throw StateError('Image has no dimensions');
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(Colors.black, BlendMode.src);
    if (baseMask != null) canvas.drawImage(baseMask!, Offset.zero, Paint());
    _drawStrokes(canvas, strokes, mask: true);
    final picture = recorder.endRecording();
    try {
      return await picture.toImage(
        imageSize.width.round(),
        imageSize.height.round(),
      );
    } finally {
      picture.dispose();
    }
  }
}

class ObjectMaskEditor extends StatefulWidget {
  const ObjectMaskEditor({
    super.key,
    required this.image,
    required this.width,
    required this.height,
    required this.controller,
    required this.tool,
    required this.masks,
    required this.onPoint,
    required this.onBox,
    this.enabled = true,
  });
  final RoomImage image;
  final int width, height;
  final ObjectMaskEditorController controller;
  final MaskTool tool;
  final List<SelectedObjectMask> masks;
  final ValueChanged<Offset> onPoint;
  final ValueChanged<Rect> onBox;
  final bool enabled;
  @override
  State<ObjectMaskEditor> createState() => _ObjectMaskEditorState();
}

class _ObjectMaskEditorState extends State<ObjectMaskEditor> {
  Offset? _start;
  MaskStroke? _stroke;
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 342 / 260,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final transform = ImageCoverTransform(
            Size(widget.width.toDouble(), widget.height.toDouble()),
            constraints.biggest,
          );
          widget.controller.imageSize = transform.imageSize;
          return GestureDetector(
            onTapUp: !widget.enabled
                ? null
                : (event) {
                    if (widget.tool == MaskTool.point) {
                      widget.onPoint(transform.toImage(event.localPosition));
                    }
                  },
            onPanStart: !widget.enabled || widget.tool == MaskTool.point
                ? null
                : (event) {
                    final point = transform.toImage(event.localPosition);
                    if (widget.tool == MaskTool.box) {
                      _start = point;
                    } else {
                      _stroke = MaskStroke(
                        erase: widget.tool == MaskTool.erase,
                        width:
                            22 *
                            transform.source.width /
                            transform.destination.width,
                        points: [point],
                      );
                      widget.controller.strokes.add(_stroke!);
                    }
                    widget.controller.changed();
                  },
            onPanUpdate: !widget.enabled || widget.tool == MaskTool.point
                ? null
                : (event) {
                    final point = transform.toImage(event.localPosition);
                    if (widget.tool == MaskTool.box && _start != null) {
                      widget.controller.box = Rect.fromPoints(_start!, point);
                    } else {
                      _stroke?.points.add(point);
                    }
                    widget.controller.changed();
                  },
            onPanEnd: !widget.enabled
                ? null
                : (_) {
                    final box = widget.controller.box;
                    if (widget.tool == MaskTool.box &&
                        box != null &&
                        box.width > 2 &&
                        box.height > 2) {
                      widget.onBox(box);
                    }
                    _stroke = null;
                    _start = null;
                  },
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(
                  widget.image.bytes,
                  fit: BoxFit.cover,
                  cacheWidth: 1600,
                ),
                ...widget.masks.map(
                  (mask) => IgnorePointer(
                    child: Image.memory(
                      mask.overlay,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: widget.controller,
                  builder: (_, _) => IgnorePointer(
                    child: CustomPaint(
                      painter: _ManualMaskPainter(widget.controller, transform),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

void _drawStrokes(
  Canvas canvas,
  List<MaskStroke> strokes, {
  required bool mask,
}) {
  for (final stroke in strokes) {
    final paint = Paint()
      ..color = stroke.erase
          ? Colors.black
          : (mask ? Colors.white : const Color(0x99315C47))
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    if (!mask && stroke.erase) paint.blendMode = BlendMode.clear;
    if (stroke.points.length == 1) {
      canvas.drawCircle(
        stroke.points.first,
        stroke.width / 2,
        paint..style = PaintingStyle.fill,
      );
    } else {
      final path = Path()
        ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (final point in stroke.points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }
}

class _ManualMaskPainter extends CustomPainter {
  _ManualMaskPainter(this.controller, this.transform);
  final ObjectMaskEditorController controller;
  final ImageCoverTransform transform;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.translate(transform.destination.left, transform.destination.top);
    canvas.scale(
      transform.destination.width / transform.source.width,
      transform.destination.height / transform.source.height,
    );
    canvas.translate(-transform.source.left, -transform.source.top);
    if (controller.baseMask != null) {
      canvas.drawImage(
        controller.baseMask!,
        Offset.zero,
        Paint()
          ..colorFilter = const ColorFilter.matrix([
            0,
            0,
            0,
            0,
            49,
            0,
            0,
            0,
            0,
            92,
            0,
            0,
            0,
            0,
            71,
            .45,
            0,
            0,
            0,
            0,
          ]),
      );
    }
    _drawStrokes(canvas, controller.strokes, mask: false);
    if (controller.box != null) {
      canvas.drawRect(
        controller.box!,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth =
              2 * transform.source.width / transform.destination.width,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ManualMaskPainter oldDelegate) => true;
}
