import 'package:flutter/material.dart';

import '../services/room_image_service.dart';

class RoomImagePreview extends StatelessWidget {
  const RoomImagePreview({
    super.key,
    required this.image,
    this.fit = BoxFit.contain,
  });
  final RoomImage image;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) => Image.memory(
    image.bytes,
    fit: fit,
    cacheWidth: 1600,
    gaplessPlayback: true,
    semanticLabel: 'Таны өрөөний зураг',
    errorBuilder: (_, _, _) => const Center(
      child: Text('Зургийг харуулах боломжгүй байна. Өөр зураг сонгоно уу.'),
    ),
  );
}
