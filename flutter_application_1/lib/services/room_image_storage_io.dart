import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> storeRoomImage(
  Uint8List bytes,
  String extension,
  String sourcePath,
) async {
  final root = await getApplicationSupportDirectory();
  final directory = await Directory(p.join(root.path, 'room_images'))
      .create(recursive: true);
  final file = File(
    p.join(
      directory.path,
      'room_${DateTime.now().microsecondsSinceEpoch}$extension',
    ),
  );
  try {
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  } catch (_) {
    if (await file.exists()) await file.delete();
    rethrow;
  }
}
