import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/room_design_project.dart';
import 'project_image_cleanup.dart'
    if (dart.library.io) 'project_image_cleanup_io.dart';
import 'room_image_storage.dart'
    if (dart.library.io) 'room_image_storage_io.dart';

class ProjectStore extends ChangeNotifier {
  static final instance = ProjectStore();
  final List<SavedDesignProject> _items = [];
  List<SavedDesignProject> get items => List.unmodifiable(_items);
  bool loaded = false;
  Future<void> load() async {
    if (loaded) return;
    final raw = (await SharedPreferences.getInstance()).getString(
      'sanaa.projects.v1',
    );
    final values = raw == null
        ? <SavedDesignProject>[]
        : (jsonDecode(raw) as List)
              .map(
                (j) => SavedDesignProject.fromJson(
                  Map<String, dynamic>.from(j as Map),
                ),
              )
              .toList();
    _items
      ..clear()
      ..addAll(values);
    loaded = true;
    notifyListeners();
  }

  Future<void> _commit(List<SavedDesignProject> values) async {
    if (!await (await SharedPreferences.getInstance()).setString(
      'sanaa.projects.v1',
      jsonEncode(values.map((p) => p.toJson()).toList()),
    )) {
      throw StateError('Хадгалж чадсангүй');
    }
    _items
      ..clear()
      ..addAll(values);
    notifyListeners();
  }

  Future<void> put(SavedDesignProject project) async {
    await load();
    final previous = find(project.id);
    await _commit([project, ..._items.where((p) => p.id != project.id)]);
    await _cleanup(previous);
  }

  Future<void> delete(String id) async {
    final previous = find(id);
    await _commit(_items.where((p) => p.id != id).toList());
    await _cleanup(previous);
  }

  Future<void> _cleanup(SavedDesignProject? old) async {
    final path = old?.previewPath;
    if (path == null || path == old?.originalPath || path == old?.emptyPath) {
      return;
    }
    if (_items.any(
      (p) => [p.previewPath, p.originalPath, p.emptyPath].contains(path),
    )) {
      return;
    }
    try {
      await removeOwnedPreview(path);
    } catch (_) {
      /* Metadata is committed; keep the unreferenced file if cleanup fails. */
    }
  }

  SavedDesignProject? find(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  static Future<String> storeImage(Uint8List bytes) async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Вэб дээр дотоод зураг хадгалах боломж хараахан холбогдоогүй. Серверийн төслөө ашиглана уу.',
      );
    }
    return storeRoomImage(bytes, '.png', '');
  }
}
