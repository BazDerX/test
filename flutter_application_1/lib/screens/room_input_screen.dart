import 'package:flutter/material.dart';

import '../services/room_image_service.dart';
import '../theme/app_theme.dart';
import '../widgets/room_image_preview.dart';
import '../widgets/room_progress_indicator.dart';
import 'room_photo_preview_screen.dart';
import 'room_scan_screen.dart';

class RoomInputScreen extends StatefulWidget {
  const RoomInputScreen({super.key, this.imageService});
  final RoomImageService? imageService;
  @override
  State<RoomInputScreen> createState() => _RoomInputScreenState();
}

class _RoomInputScreenState extends State<RoomInputScreen> {
  RoomImageService get _images =>
      widget.imageService ?? RoomImageService.instance;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _perform(_images.recoverLostImage);
    });
  }

  Future<void> _perform(Future<RoomImage?> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final image = await action();
      if (!mounted || image == null) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              RoomPhotoPreviewScreen(image: image, imageService: _images),
        ),
      );
    } on RoomImageException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Зургийг нээж чадсангүй. Дахин оролдоно уу.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _scan() => _perform(
    () => Navigator.push<RoomImage>(
      context,
      MaterialPageRoute(builder: (_) => RoomScanScreen(imageService: _images)),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Өрөөгөө оруулах'),
      leading: IconButton(
        tooltip: 'Буцах',
        icon: const Icon(Icons.arrow_back, size: 20),
        onPressed: () => Navigator.maybePop(context),
      ),
    ),
    body: SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RoomProgressIndicator(),
                const SizedBox(height: 22),
                const Text(
                  'Эхлээд өрөөтэй танилцъя.',
                  style: TextStyle(
                    fontSize: 28,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 22),
                ValueListenableBuilder<RoomImage?>(
                  valueListenable: _images.current,
                  builder: (context, image, _) => Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: 342 / 220,
                          child: image == null
                              ? Image.asset(
                                  'assets/images/room_input.png',
                                  fit: BoxFit.cover,
                                  excludeFromSemantics: true,
                                )
                              : RoomImagePreview(
                                  image: image,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      if (image != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _perform(() async => image),
                              child: const Text('Зураг харах'),
                            ),
                            TextButton(
                              onPressed: _busy ? null : _images.clear,
                              child: const Text('Зураг хасах'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _scan,
                    icon: const Icon(Icons.crop_free, size: 18),
                    label: const Text('Камераар скан хийх'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Өрөөний хэмжээ, ханыг илүү сайн танина.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppTheme.muted),
                  ),
                ),
                const Center(
                  child: Text(
                    '3D танилт удахгүй · одоогоор зураг авна.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppTheme.muted),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _perform(_images.pickFromGallery),
                    icon: const Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 19,
                    ),
                    label: const Text('Өрөөний зураг оруулах'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppTheme.border),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Гэрэл сайтай, булангууд нь харагдсан зураг сонгоорой.',
                  style: TextStyle(fontSize: 12, color: AppTheme.muted),
                ),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(
                      semanticsLabel: 'Зураг нээж байна',
                    ),
                  ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EFE7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 18,
                        color: AppTheme.green,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Таны зураг зөвхөн тохижуулалт үүсгэхэд ашиглагдана. Хуваалцах эсэхийг та өөрөө шийднэ.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: AppTheme.green,
                          ),
                        ),
                      ),
                    ],
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
