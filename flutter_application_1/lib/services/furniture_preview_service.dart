import 'package:flutter/material.dart';

import '../models/furniture.dart';

/// Single integration point for a future native 3D viewer / AR placement adapter.
abstract interface class FurniturePreviewService {
  Future<void> showModel(BuildContext context, Furniture product);
  Future<void> placeInRoom(BuildContext context, Furniture product);
}

class UnavailableFurniturePreview implements FurniturePreviewService {
  const UnavailableFurniturePreview();
  Future<void> _message(BuildContext context, String message) =>
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('3D / AR загвар'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ойлголоо'),
            ),
          ],
        ),
      );
  @override
  Future<void> showModel(BuildContext context, Furniture product) =>
      _message(context, '3D загвар бэлэн болоогүй байна.');
  @override
  Future<void> placeInRoom(BuildContext context, Furniture product) => _message(
    context,
    'AR-аар байрлуулах боломж бэлэн болоогүй байна. Тохирох 3D загвар болон AR холболт шаардлагатай.',
  );
}
