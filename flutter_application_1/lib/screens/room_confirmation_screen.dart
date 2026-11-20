import 'package:flutter/material.dart';

import '../models/room_design_project.dart';
import '../models/design_preferences.dart';
import '../services/room_image_service.dart';
import '../services/design_draft_store.dart';
import '../widgets/design_screen_layout.dart';
import '../widgets/primary_button.dart';
import '../widgets/room_image_preview.dart';
import '../widgets/room_progress_indicator.dart';
import '../theme/app_theme.dart';
import 'room_scan_screen.dart';
import 'style_selection_screen.dart';

class RoomConfirmationScreen extends StatefulWidget {
  const RoomConfirmationScreen({
    super.key,
    required this.image,
    this.imageService,
  });
  final RoomImage image;
  final RoomImageService? imageService;
  @override
  State<RoomConfirmationScreen> createState() => _RoomConfirmationScreenState();
}

class _RoomConfirmationScreenState extends State<RoomConfirmationScreen> {
  late RoomDesignProject _draft = RoomDesignProject(sourceImage: widget.image);
  bool _busy = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _validate();
  }

  Future<void> _validate() async {
    try {
      await DesignDraftStore.validate(_draft.sourceImage);
      if (mounted) setState(() => _error = null);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Зургийн файл олдсонгүй эсвэл гэмтсэн байна. Өөр зураг сонгоно уу.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _replace() async {
    final camera = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Дахин зураг авах'),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Өөр зураг сонгох'),
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
    if (camera == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final service = widget.imageService ?? RoomImageService.instance;
      final image = camera
          ? await Navigator.push<RoomImage>(
              context,
              MaterialPageRoute(
                builder: (_) => RoomScanScreen(imageService: service),
              ),
            )
          : await service.pickFromGallery();
      if (image != null && mounted) {
        setState(
          () => _draft = RoomDesignProject(
            sourceImage: image,
            preferences: _draft.preferences,
          ),
        );
        await _validate();
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

  Future<void> _continue() async {
    setState(() => _busy = true);
    try {
      await DesignDraftStore.save(_draft);
      if (mounted) {
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => StyleSelectionScreen(draft: _draft),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ноорог хадгалж чадсангүй. Төхөөрөмжийн зайг шалгана уу.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => DesignScreenLayout(
    title: 'Өрөөгөө шалгах',
    children: [
      const RoomProgressIndicator(),
      const SizedBox(height: 22),
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 1,
          child: RoomImagePreview(image: _draft.sourceImage, fit: BoxFit.cover),
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _busy ? null : _replace,
          icon: const Icon(Icons.sync, size: 18),
          label: const Text('Дахин авах / Зураг солих'),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            side: const BorderSide(color: AppTheme.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      const SizedBox(height: 22),
      const Text(
        'Ямар өрөө вэ?',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        children: DesignPreferences.roomTypes.entries
            .map(
              (entry) => ChoiceChip(
                label: Text(entry.value, style: const TextStyle(fontSize: 12)),
                selected: _draft.preferences.roomType == entry.key,
                onSelected: _busy
                    ? null
                    : (_) => setState(
                        () => _draft.preferences = _draft.preferences.copyWith(
                          roomType: entry.key,
                        ),
                      ),
                selectedColor: AppTheme.green,
                labelStyle: TextStyle(
                  color: _draft.preferences.roomType == entry.key
                      ? Colors.white
                      : AppTheme.ink,
                ),
                showCheckmark: false,
                shape: const StadiumBorder(),
                side: const BorderSide(color: AppTheme.border),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 18),
      if (_busy) const LinearProgressIndicator(),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8EFE7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _error == null ? Icons.info_outline : Icons.error_outline,
              size: 18,
              color: AppTheme.green,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error ?? 'Гэрэл сайтай, шал болон ханын булангууд харагдсан зураг сонгоорой. Хана, хэмжээсийг автоматаар таниагүй.',
                style: const TextStyle(fontSize: 12, color: AppTheme.green),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      PrimaryButton(
        label: 'Үргэлжлүүлэх',
        onPressed: _busy || _error != null ? null : _continue,
      ),
    ],
  );
}
