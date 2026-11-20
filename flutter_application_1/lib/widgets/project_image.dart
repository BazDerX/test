import 'package:flutter/material.dart';

import '../services/room_image_service.dart';
import '../services/draft_image_reader.dart'
    if (dart.library.io) '../services/draft_image_reader_io.dart';

class ProjectImage extends StatelessWidget {
  const ProjectImage({super.key, required this.path});
  final String? path;
  static Future<RoomImage?> read(String? path) async =>
      path == null ? null : readDraftImage(path);
  @override
  Widget build(BuildContext context) => FutureBuilder<RoomImage?>(
    future: read(path),
    builder: (context, snapshot) => snapshot.data == null
        ? const ColoredBox(
            color: Color(0xFFEAE7DF),
            child: Center(child: Text('Зураг олдсонгүй')),
          )
        : Image.memory(snapshot.data!.bytes, fit: BoxFit.cover),
  );
}
