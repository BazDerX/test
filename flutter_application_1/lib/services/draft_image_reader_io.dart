import 'dart:io';

import 'room_image_service.dart';

Future<RoomImage?> readDraftImage(String path) async {
  final file = File(path);
  if (!await file.exists()) return null;
  return RoomImage(path: path, bytes: await file.readAsBytes());
}

Future<bool> roomImageFileExists(String path) => File(path).exists();
