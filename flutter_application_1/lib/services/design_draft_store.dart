import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/design_preferences.dart';
import '../models/room_design_project.dart';
import 'room_image_service.dart';
import 'ai_api_service.dart';
import 'draft_image_reader.dart'
    if (dart.library.io) 'draft_image_reader_io.dart';

class DesignDraftStore {
  static const _key = 'sanaa.design.draft.v1';
  static Future<void> save(RoomDesignProject draft) async {
    final data = {
      'source_path': draft.sourceImage.path,
      'working_path': draft.workingImage.path,
      if (kIsWeb) 'source_bytes': base64Encode(draft.sourceImage.bytes),
      if (kIsWeb) 'working_bytes': base64Encode(draft.workingImage.bytes),
      'preferences': draft.preferences.toJson(),
      'room_id': draft.roomId,
      'source_image_id': draft.sourceImageId,
      'working_image_id': draft.workingImageId,
      'width': draft.width,
      'height': draft.height,
      'previous_job_ids': draft.previousJobIds,
      'masks': draft.masks
          .map(
            (mask) => {
              'id': mask.id,
              'manual': mask.manual,
              'overlay': base64Encode(mask.overlay),
            },
          )
          .toList(),
      'accepted_mask_ids': draft.acceptedMaskIds,
      'backend': AiApiService.instance.baseUrl,
    };
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_key, jsonEncode(data))) {
      throw StateError('Draft storage failed');
    }
  }

  static Future<RoomDesignProject?> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      Future<RoomImage?> image(String key) async => kIsWeb
          ? RoomImage(
              path: data['${key}_path'] as String,
              bytes: base64Decode(data['${key}_bytes'] as String),
            )
          : readDraftImage(data['${key}_path'] as String);
      final source = await image('source');
      if (source == null) return null;
      final draft = RoomDesignProject(
        sourceImage: source,
        preferences: DesignPreferences.fromJson(
          Map<String, dynamic>.from(data['preferences'] as Map),
        ),
      );
      draft.workingImage = await image('working') ?? source;
      if (data['backend'] == AiApiService.instance.baseUrl) {
        draft.roomId = data['room_id'] as String?;
        draft.sourceImageId = data['source_image_id'] as String?;
        draft.workingImageId = data['working_image_id'] as String?;
        draft.previousJobIds.addAll(
          (data['previous_job_ids'] as List? ?? []).cast<String>(),
        );
        for (final item in data['masks'] as List? ?? []) {
          final mask = item as Map;
          draft.masks.add(
            SelectedObjectMask(
              id: mask['id'] as String,
              manual: mask['manual'] as bool,
              overlay: base64Decode(mask['overlay'] as String),
            ),
          );
        }
        draft.acceptedMaskIds.addAll(
          (data['accepted_mask_ids'] as List? ?? []).cast<String>(),
        );
      } else {
        draft.workingImage = source;
      }
      draft.width = data['width'] as int? ?? 0;
      draft.height = data['height'] as int? ?? 0;
      return draft;
    } catch (_) {
      return null;
    }
  }

  static Future<void> validate(RoomImage image) async {
    if (!await roomImageFileExists(image.path)) {
      throw const RoomImageException(
        'Зургийн файл олдсонгүй. Зургаа дахин сонгоно уу.',
      );
    }
    final codec = await ui.instantiateImageCodec(
      image.bytes,
      targetWidth: 1000,
      allowUpscaling: false,
    );
    try {
      final frame = await codec.getNextFrame();
      frame.image.dispose();
    } finally {
      codec.dispose();
    }
  }
}
