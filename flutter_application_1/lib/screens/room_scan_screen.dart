import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show DeviceOrientation;

import '../services/room_image_service.dart';
import '../theme/app_theme.dart';
import '../widgets/camera_scan_overlay.dart';

class RoomScanScreen extends StatefulWidget {
  const RoomScanScreen({super.key, this.imageService});
  final RoomImageService? imageService;
  @override
  State<RoomScanScreen> createState() => _RoomScanScreenState();
}

class _RoomScanScreenState extends State<RoomScanScreen>
    with WidgetsBindingObserver {
  RoomImageService get _images =>
      widget.imageService ?? RoomImageService.instance;
  CameraController? _controller;
  Future<void> _cameraQueue = Future<void>.value();
  int _generation = 0;
  bool _initializing = true, _busy = false, _away = false, _foreground = true;
  String? _error;
  FlashMode _flash = FlashMode.off;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  // Queue disposal and initialization so lifecycle changes cannot open two
  // camera sessions at once. Generation checks discard stale async results.
  void _start() {
    if (!mounted || _away || !_foreground || _controller != null) return;
    final generation = ++_generation;
    setState(() {
      _initializing = true;
      _error = null;
    });
    _cameraQueue = _cameraQueue.then((_) async {
      if (!mounted || generation != _generation) return;
      CameraController? candidate;
      try {
        if (!kIsWeb &&
            defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS) {
          throw CameraException(
            'unavailable',
            'Камер энэ платформ дээр дэмжигдээгүй. Зургийн сангаас зураг сонгоно уу.',
          );
        }
        final cameras = await availableCameras();
        if (!mounted || generation != _generation) return;
        if (cameras.isEmpty) {
          throw CameraException(
            'unavailable',
            'Камер олдсонгүй. Зургийн сангаас зураг сонгоно уу.',
          );
        }
        final rear = cameras.where(
          (camera) => camera.lensDirection == CameraLensDirection.back,
        );
        candidate = CameraController(
          rear.isEmpty ? cameras.first : rear.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await candidate.initialize();
        if (!mounted || generation != _generation) {
          await candidate.dispose();
          return;
        }
        var initialFlash = FlashMode.off;
        try {
          await candidate.setFlashMode(FlashMode.auto);
          initialFlash = FlashMode.auto;
        } catch (_) {
          /* Camera may have no flash. */
        }
        if (!mounted || generation != _generation) {
          await candidate.dispose();
          return;
        }
        setState(() {
          _controller = candidate;
          _flash = initialFlash;
          _initializing = false;
        });
      } catch (error) {
        if (candidate != null) {
          try {
            await candidate.dispose();
          } catch (_) {}
        }
        if (mounted && generation == _generation) {
          setState(() {
            _initializing = false;
            _error = _cameraError(error);
          });
        }
      }
    });
  }

  Future<void> _stop() {
    ++_generation;
    final controller = _controller;
    _controller = null;
    _cameraQueue = _cameraQueue.then((_) async {
      if (controller != null) {
        try {
          await controller.dispose();
        } catch (_) {}
      }
    });
    return _cameraQueue;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      if (!_away) _start();
    } else {
      unawaited(_stop());
      if (mounted) setState(() => _initializing = true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_stop());
    super.dispose();
  }

  String _cameraError(Object error) {
    if (error is CameraException) {
      switch (error.code) {
        case 'CameraAccessDenied':
          return 'Камерын зөвшөөрөл олгогдоогүй байна. Зөвшөөрлийг дахин өгөх эсвэл төхөөрөмжийн тохиргооноос SANAA камерын эрхийг нээнэ үү.';
        case 'CameraAccessDeniedWithoutPrompt':
        case 'CameraAccessRestricted':
          return 'Камерын зөвшөөрөл хаалттай байна. Төхөөрөмжийн тохиргоо → SANAA → Камер хэсэгт зөвшөөрөл өгнө үү.';
        case 'unavailable':
          return error.description!;
      }
    }
    return 'Камерыг нээж чадсангүй. Өөр апп камер ашиглаж байгаа эсэхийг шалгаад дахин оролдоно уу.';
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (_busy ||
        controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return;
    }
    setState(() => _busy = true);
    try {
      final file = await controller.takePicture();
      final image = await _images.importImage(file);
      if (!mounted) return;
      _away = true;
      await _stop();
      if (mounted) Navigator.pop(context, image);
    } on RoomImageException catch (error) {
      _message(error.message);
    } catch (_) {
      _message(
        'Зураг авч чадсангүй. Камер бэлэн болсон үед дахин оролдоно уу.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _gallery() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _away = true;
    });
    await _stop();
    try {
      final image = await _images.pickFromGallery();
      if (!mounted) return;
      if (image != null) {
        Navigator.pop(context, image);
        return;
      }
    } on RoomImageException catch (error) {
      _message(error.message);
    } catch (_) {
      _message('Зургийн санг нээж чадсангүй. Дахин оролдоно уу.');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _away = false;
        });
        if (ModalRoute.of(context)?.isCurrent ?? false) _start();
      }
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (_busy || controller == null) return;
    final next = switch (_flash) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.always,
      _ => FlashMode.off,
    };
    setState(() => _busy = true);
    try {
      await controller.setFlashMode(next);
      if (mounted && _controller == controller) setState(() => _flash = next);
    } catch (_) {
      _message('Энэ камер сонгосон гэрлийн горимыг дэмжихгүй байна.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _livePreview(CameraController controller) =>
      ValueListenableBuilder<CameraValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          if (value.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Камерын холболт тасарлаа. Буцаад дахин нээнэ үү.',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          }
          // CameraPreview handles sensor/device rotation. FittedBox crops its
          // oriented aspect ratio to the viewport, without stretching the feed.
          final orientation =
              value.previewPauseOrientation ??
              value.lockedCaptureOrientation ??
              value.deviceOrientation;
          final landscape =
              orientation == DeviceOrientation.landscapeLeft ||
              orientation == DeviceOrientation.landscapeRight;
          final ratio = landscape ? value.aspectRatio : 1 / value.aspectRatio;
          return ClipRect(
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: 1000 * ratio,
                  height: 1000,
                  child: CameraPreview(controller),
                ),
              ),
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Өрөө скан хийх'),
        leading: IconButton(
          tooltip: 'Буцах',
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ColoredBox(
              color: const Color(0xFF27312C),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (ready) _livePreview(controller),
                  if (_initializing && !_away)
                    const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Камерыг бэлдэж байна…',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  if (_error != null)
                    Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.no_photography_outlined,
                              color: Colors.white,
                              size: 36,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _busy ? null : _start,
                              child: const Text('Дахин оролдох'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (ready) ...[
                    const CameraScanOverlay(),
                    Positioned(
                      top: 18,
                      left: 24,
                      right: 24,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xF5FFFFFF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.open_with,
                                size: 18,
                                color: AppTheme.green,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Утсаа аажуухан хөдөлгөж, ханын булангуудыг хамруулаарай.',
                                  style: TextStyle(fontSize: 12, height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 24,
                      right: 24,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xE6315C47),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _busy
                                    ? 'Зургийг боловсруулж байна…'
                                    : 'Камер бэлэн · өрөөний зураг авна',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                              if (_busy)
                                const Padding(
                                  padding: EdgeInsets.only(top: 10),
                                  child: LinearProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              const Text(
                                '3D скан, хана болон хэмжээс танилт хараахан холбогдоогүй.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _busy ? null : _gallery,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_library_outlined, size: 23),
                          SizedBox(height: 4),
                          Text('Зургийн сан', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                  Semantics(
                    label: 'Өрөөний зураг авах',
                    button: true,
                    child: SizedBox(
                      width: 76,
                      height: 76,
                      child: OutlinedButton(
                        onPressed: ready && !_busy ? _capture : null,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(5),
                          side: const BorderSide(
                            color: AppTheme.green,
                            width: 2,
                          ),
                          shape: const CircleBorder(),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ready && !_busy
                                ? AppTheme.green
                                : AppTheme.muted,
                          ),
                          child: _busy
                              ? const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: ready && !_busy ? _toggleFlash : null,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _flash == FlashMode.off
                                ? Icons.flash_off_outlined
                                : _flash == FlashMode.auto
                                ? Icons.flash_auto_outlined
                                : Icons.flash_on_outlined,
                            size: 23,
                          ),
                          const SizedBox(height: 4),
                          Text(switch (_flash) {
                            FlashMode.auto => 'Автомат',
                            FlashMode.always => 'Асаалттай',
                            _ => 'Унтраалттай',
                          }, style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
