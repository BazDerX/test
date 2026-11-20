import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<void> removeOwnedPreview(String path) async {
  final root = await getApplicationSupportDirectory();
  final directory = p.join(root.path, 'room_images');
  if (!p.isWithin(directory, p.normalize(p.absolute(path)))) return;
  final file = File(path);
  if (await file.exists()) await file.delete();
}
