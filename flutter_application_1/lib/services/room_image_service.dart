import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import 'room_image_storage.dart'
    if (dart.library.io) 'room_image_storage_io.dart'
    as storage;

class RoomImage {
  const RoomImage({required this.path, required this.bytes});
  final String path;
  final Uint8List bytes;
}

class RoomImageException implements Exception {
  const RoomImageException(this.message);
  final String message;
}

typedef RoomImageStore = Future<String> Function(
  Uint8List bytes,
  String extension,
  String sourcePath,
);

/// Imports real images locally. This service never sends an image over a network.
class RoomImageService {
  RoomImageService({ImagePicker? picker, RoomImageStore? store})
    : _picker = picker ?? ImagePicker(),
      _store = store ?? storage.storeRoomImage;
  static final instance = RoomImageService();
  final ImagePicker _picker;
  final RoomImageStore _store;
  final current = ValueNotifier<RoomImage?>(null);
  static const maxBytes = 30 * 1024 * 1024;

  Future<RoomImage?> pickFromGallery() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
      return image == null ? null : await importImage(image);
    } on PlatformException catch (error) {
      if (error.code.contains('access') || error.code.contains('denied')) {
        throw const RoomImageException(
          'Зургийн сангийн зөвшөөрөл хаалттай байна. Төхөөрөмжийн тохиргооноос SANAA-д зөвшөөрөл өгнө үү.',
        );
      }
      throw const RoomImageException(
        'Зургийн санг нээж чадсангүй. Дахин оролдоно уу.',
      );
    }
  }

  Future<RoomImage?> recoverLostImage() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final response = await _picker.retrieveLostData();
    if (response.exception != null) {
      throw const RoomImageException(
        'Өмнө сонгосон зургийг сэргээж чадсангүй. Дахин сонгоно уу.',
      );
    }
    final files = response.files;
    return files == null || files.isEmpty ? null : importImage(files.first);
  }

  Future<RoomImage> importImage(XFile file) async {
    try {
      final length = await file.length();
      if (length == 0 || length > maxBytes) {
        throw const RoomImageException(
          '30 МБ-аас бага хэмжээтэй, хоосон биш зураг сонгоно уу.',
        );
      }
      final bytes = await file.readAsBytes();
      // Validate the actual contents, not only the extension. Native codecs also
      // accept device formats such as HEIC when supported by the OS.
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 1600,
        allowUpscaling: false,
      );
      try {
        final frame = await codec.getNextFrame();
        frame.image.dispose();
      } finally {
        codec.dispose();
      }
      var extension = p.extension(file.name).toLowerCase();
      if (!RegExp(r'^\.[a-z0-9]{1,8}$').hasMatch(extension)) extension = '.img';
      final savedPath = await _store(bytes, extension, file.path);
      final image = RoomImage(path: savedPath, bytes: bytes);
      current.value = image;
      return image;
    } on RoomImageException {
      rethrow;
    } catch (_) {
      throw const RoomImageException(
        'Зургийг уншиж эсвэл хадгалж чадсангүй. Дэмжигдсэн JPG, PNG эсвэл төхөөрөмжийн зураг сонгоно уу.',
      );
    }
  }

  void clear() => current.value = null;
}
