import 'dart:typed_data';

// Browser images stay in this session; native builds use private app storage.
Future<String> storeRoomImage(
  Uint8List bytes,
  String extension,
  String sourcePath,
) async => sourcePath;
