import 'package:flutter/material.dart';

import '../services/room_image_service.dart';
import '../widgets/primary_button.dart';
import '../widgets/room_image_preview.dart';
import 'room_scan_screen.dart';
import 'room_confirmation_screen.dart';

class RoomPhotoPreviewScreen extends StatefulWidget {
  const RoomPhotoPreviewScreen({
    super.key,
    required this.image,
    this.imageService,
  });
  final RoomImage image;
  final RoomImageService? imageService;
  @override
  State<RoomPhotoPreviewScreen> createState() => _RoomPhotoPreviewScreenState();
}

class _RoomPhotoPreviewScreenState extends State<RoomPhotoPreviewScreen> {
  late RoomImage _image = widget.image;
  RoomImageService get _images =>
      widget.imageService ?? RoomImageService.instance;
  bool _busy = false;
  Future<void> _replace(bool camera) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final image = camera
          ? await Navigator.push<RoomImage>(
              context,
              MaterialPageRoute(
                builder: (_) => RoomScanScreen(imageService: _images),
              ),
            )
          : await _images.pickFromGallery();
      if (mounted && image != null) setState(() => _image = image);
    } on RoomImageException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Зургийг сольж чадсангүй. Дахин оролдоно уу.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Буцах',
        icon: const Icon(Icons.arrow_back, size: 20),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: const Text('Өрөөний зураг'),
      actions: [
        IconButton(
          tooltip: 'Зураг хасах',
          onPressed: _busy
              ? null
              : () {
                  _images.clear();
                  Navigator.pop(context);
                },
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: RoomImagePreview(image: _image),
                  ),
                ),
                const SizedBox(height: 16),
                if (_busy)
                  const LinearProgressIndicator(
                    semanticsLabel: 'Зургийг боловсруулж байна',
                  ),
                TextButton.icon(
                  onPressed: _busy ? null : () => _replace(true),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Дахин зураг авах'),
                ),
                TextButton.icon(
                  onPressed: _busy ? null : () => _replace(false),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Өөр зураг сонгох'),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Үргэлжлүүлэх',
                  onPressed: _busy
                      ? null
                      : () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RoomConfirmationScreen(
                              image: _image,
                              imageService: _images,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
