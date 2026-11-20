import 'dart:typed_data';

import '../services/room_image_service.dart';
import 'design_preferences.dart';

class SelectedObjectMask {
  const SelectedObjectMask({
    required this.id,
    required this.overlay,
    required this.manual,
  });
  final String id;
  final Uint8List overlay;
  final bool manual;
}

/// One typed draft shared across confirmation, preferences, editing and results.
class RoomDesignProject {
  RoomDesignProject({required this.sourceImage, DesignPreferences? preferences})
    : workingImage = sourceImage,
      preferences = preferences ?? const DesignPreferences();
  final RoomImage sourceImage;
  RoomImage workingImage;
  DesignPreferences preferences;
  String? roomId, sourceImageId, workingImageId;
  int width = 0, height = 0;
  final List<SelectedObjectMask> masks = [];
  final List<String> acceptedMaskIds = [];
  final List<String> previousJobIds = [];
  bool get cleaned => workingImageId != null && workingImageId != sourceImageId;
}

class SavedDesignProject {
  const SavedDesignProject({
    required this.id,
    required this.name,
    required this.jobId,
    required this.sourceImageId,
    required this.outputImageId,
    required this.preferences,
    required this.created,
    this.originalPath,
    this.emptyPath,
    this.previewPath,
    this.roomId,
    this.placements = const [],
    this.updated,
    this.saved = true,
    this.backgroundImageId,
  });
  final String id, name, jobId, sourceImageId, outputImageId;
  final DesignPreferences preferences;
  final double created;
  final String? originalPath, emptyPath, previewPath, roomId;
  final List<PlacedFurniture> placements;
  final double? updated;
  final bool saved;
  final String? backgroundImageId;
  factory SavedDesignProject.fromJson(Map<String, dynamic> json) =>
      SavedDesignProject(
        id: json['id'] as String,
        backgroundImageId: json['background_image_id'] as String?,
        name: json['name'] as String,
        jobId: json['job_id'] as String,
        sourceImageId: json['source_image_id'] as String,
        outputImageId: json['output_image_id'] as String,
        preferences: DesignPreferences.fromJson(
          Map<String, dynamic>.from(json['preferences'] as Map),
        ),
        created: (json['created'] as num).toDouble(),
        originalPath: json['original_path'] as String?,
        emptyPath: json['empty_path'] as String?,
        previewPath: json['preview_path'] as String?,
        roomId: json['room_id'] as String?,
        updated: (json['updated'] as num?)?.toDouble(),
        saved: json['saved'] as bool? ?? true,
        placements: (json['placements'] as List? ?? [])
            .map(
              (value) => PlacedFurniture.fromJson(
                Map<String, dynamic>.from(value as Map),
              ),
            )
            .toList(),
      );
  Map<String, dynamic> toJson() => {
    'background_image_id': backgroundImageId,
    'id': id,
    'name': name,
    'job_id': jobId,
    'source_image_id': sourceImageId,
    'output_image_id': outputImageId,
    'preferences': preferences.toJson(),
    'created': created,
    'updated': updated,
    'original_path': originalPath,
    'empty_path': emptyPath,
    'preview_path': previewPath,
    'room_id': roomId,
    'saved': saved,
    'placements': placements.map((p) => p.toJson()).toList(),
  };
  SavedDesignProject changed({
    String? name,
    String? previewPath,
    List<PlacedFurniture>? placements,
  }) => SavedDesignProject(
    id: id,
    backgroundImageId: backgroundImageId,
    name: name ?? this.name,
    jobId: jobId,
    sourceImageId: sourceImageId,
    outputImageId: outputImageId,
    preferences: preferences,
    created: created,
    updated: DateTime.now().millisecondsSinceEpoch / 1000,
    originalPath: originalPath,
    emptyPath: emptyPath,
    previewPath: previewPath ?? this.previewPath,
    roomId: roomId,
    placements: placements ?? this.placements,
    saved: saved,
  );
}

class PlacedFurniture {
  PlacedFurniture({
    required this.instanceId,
    required this.furnitureId,
    this.x = .5,
    this.y = .5,
    this.scale = 1,
    this.rotation = 0,
    this.layerOrder = 0,
  });
  final String instanceId, furnitureId;
  double x, y, scale, rotation;
  int layerOrder;
  Map<String, dynamic> toJson() => {
    'instance_id': instanceId,
    'furniture_id': furnitureId,
    'x': x,
    'y': y,
    'scale': scale,
    'rotation': rotation,
    'layer': layerOrder,
  };
  factory PlacedFurniture.fromJson(Map<String, dynamic> j) => PlacedFurniture(
    instanceId: j['instance_id'] as String,
    furnitureId: j['furniture_id'] as String,
    x: (j['x'] as num).toDouble(),
    y: (j['y'] as num).toDouble(),
    scale: (j['scale'] as num).toDouble(),
    rotation: (j['rotation'] as num).toDouble(),
    layerOrder: j['layer'] as int,
  );
}
