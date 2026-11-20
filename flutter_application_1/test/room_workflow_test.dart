import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/screens/room_input_screen.dart';
import 'package:flutter_application_1/screens/room_photo_preview_screen.dart';
import 'package:flutter_application_1/screens/room_scan_screen.dart';
import 'package:flutter_application_1/screens/room_confirmation_screen.dart';
import 'package:flutter_application_1/services/room_image_service.dart';
import 'package:flutter_application_1/services/room_image_storage_io.dart'
    as storage;
import 'package:flutter_application_1/theme/app_theme.dart';

class TestPicker extends ImagePicker {
  XFile? result;
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async => result;
  @override
  Future<LostDataResponse> retrieveLostData() async => LostDataResponse.empty();
}

class TestCamera extends CameraPlatform {
  XFile? photo;
  CameraException? failure;
  bool captureFails = false;
  bool available = true, flashSupported = true;
  int created = 0, disposed = 0, captures = 0;
  final initialized = StreamController<CameraInitializedEvent>.broadcast();
  final errors = StreamController<CameraErrorEvent>.broadcast();
  @override
  Future<List<CameraDescription>> availableCameras() async => available
      ? [
          const CameraDescription(
            name: 'rear',
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 90,
          ),
        ]
      : [];
  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() =>
      const Stream.empty();
  @override
  Future<int> createCameraWithSettings(
    CameraDescription description,
    MediaSettings settings,
  ) async {
    if (failure != null) throw failure!;
    expectSync(description.lensDirection, CameraLensDirection.back);
    expectSync(settings.enableAudio, isFalse);
    return ++created;
  }

  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) =>
      initialized.stream.where((event) => event.cameraId == cameraId);
  @override
  Stream<CameraErrorEvent> onCameraError(int cameraId) => errors.stream;
  @override
  Future<void> initializeCamera(
    int cameraId, {
    ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown,
  }) async {
    initialized.add(
      CameraInitializedEvent(
        cameraId,
        1280,
        720,
        ExposureMode.auto,
        true,
        FocusMode.auto,
        true,
      ),
    );
  }

  @override
  Future<void> setFlashMode(int cameraId, FlashMode mode) async {
    if (!flashSupported) throw CameraException('unsupported', 'No flash');
  }

  @override
  Widget buildPreview(int cameraId) => const ColoredBox(color: Colors.blueGrey);
  @override
  Future<XFile> takePicture(int cameraId) async {
    if (captureFails) throw CameraException('captureFailed', 'test failure');
    captures++;
    return photo!;
  }

  @override
  Future<void> dispose(int cameraId) async {
    disposed++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Uint8List bytes;
  setUpAll(() async {
    bytes = await File('assets/images/room_input.png').readAsBytes();
  });
  RoomImageService imageService(TestPicker picker) => RoomImageService(
    picker: picker,
    store: (data, extension, source) async => '/private/room$extension',
  );
  Widget app(Widget home) => MaterialApp(theme: AppTheme.light, home: home);

  test('Valid images are stored, corrupt images rejected, cancellation preserves selection', () async {
    final picker = TestPicker();
    final service = imageService(picker);
    picker.result = XFile.fromData(bytes, path: 'room.PNG');
    final image = await service.pickFromGallery();
    expect(image!.path, '/private/room.png');
    expect(image.bytes, bytes);
    picker.result = null;
    expect(await service.pickFromGallery(), isNull);
    expect(service.current.value, same(image));
    await expectLater(
      service.importImage(
        XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'fake.jpg'),
      ),
      throwsA(isA<RoomImageException>()),
    );
    expect(service.current.value, same(image));
    await expectLater(
      service.importImage(XFile.fromData(Uint8List(0), name: 'empty.png')),
      throwsA(isA<RoomImageException>()),
    );
    service.clear();
    expect(service.current.value, isNull);
  });

  test(
    'Native storage copies bytes into an app-controlled directory',
    () async {
      final root = await Directory.systemTemp.createTemp('sanaa_room_test_');
      addTearDown(() => root.delete(recursive: true));
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => root.path,
          );
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('plugins.flutter.io/path_provider'),
              null,
            ),
      );
      final saved = await storage.storeRoomImage(
        bytes,
        '.png',
        'picker/source.png',
      );
      expect(saved, startsWith(root.path));
      expect(await File(saved).readAsBytes(), bytes);
    },
  );

  testWidgets(
    'Gallery opens actual photo preview, cancellation keeps photo, continue and remove work',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final picker = TestPicker()
        ..result = XFile.fromData(bytes, name: 'room.png');
      final service = imageService(picker);
      await tester.pumpWidget(app(RoomInputScreen(imageService: service)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Өрөөний зураг оруулах'));
      await tester.tap(find.text('Өрөөний зураг оруулах'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
      expect(find.byType(RoomPhotoPreviewScreen), findsOneWidget);
      final selected = service.current.value;
      picker.result = null;
      await tester.ensureVisible(find.text('Өөр зураг сонгох'));
      await tester.tap(find.text('Өөр зураг сонгох'));
      await tester.pumpAndSettle();
      expect(service.current.value, same(selected));
      await tester.ensureVisible(find.text('Үргэлжлүүлэх'));
      await tester.tap(find.text('Үргэлжлүүлэх'));
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
      expect(find.byType(RoomConfirmationScreen), findsOneWidget);
      await tester.tap(find.byTooltip('Буцах'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Зураг хасах'));
      await tester.pumpAndSettle();
      expect(service.current.value, isNull);
      expect(find.byType(RoomInputScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Camera captures a real file through the plugin and releases its controller',
    (tester) async {
      final original = CameraPlatform.instance;
      final camera = TestCamera()
        ..photo = XFile.fromData(bytes, name: 'capture.jpg');
      CameraPlatform.instance = camera;
      addTearDown(() {
        CameraPlatform.instance = original;
      });
      final service = imageService(TestPicker());
      await tester.pumpWidget(app(RoomInputScreen(imageService: service)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Камераар скан хийх'));
      await tester.tap(find.text('Камераар скан хийх'));
      await tester.pumpAndSettle();
      expect(find.byType(CameraPreview), findsOneWidget);
      await tester.tap(find.byType(OutlinedButton));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
      expect(camera.captures, 1);
      expect(camera.disposed, camera.created);
      expect(service.current.value!.bytes, bytes);
      expect(find.byType(RoomPhotoPreviewScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'Camera releases on background, resumes, and handles unsupported flash',
    (tester) async {
      final original = CameraPlatform.instance;
      final camera = TestCamera()..flashSupported = false;
      CameraPlatform.instance = camera;
      addTearDown(() {
        CameraPlatform.instance = original;
      });
      await tester.pumpWidget(app(const RoomScanScreen()));
      await tester.pumpAndSettle();
      expect(camera.created, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(camera.disposed, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.idle();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(camera.created, 2);
      await tester.tap(find.text('Унтраалттай'));
      await tester.pumpAndSettle();
      expect(
        find.text('Энэ камер сонгосон гэрлийн горимыг дэмжихгүй байна.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(camera.disposed, camera.created);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'Denied camera permission shows guidance and leaves gallery usable',
    (tester) async {
      final original = CameraPlatform.instance;
      CameraPlatform.instance = TestCamera()
        ..failure = CameraException(
          'CameraAccessDeniedWithoutPrompt',
          'denied',
        );
      addTearDown(() {
        CameraPlatform.instance = original;
      });
      await tester.pumpWidget(app(const RoomScanScreen()));
      await tester.pumpAndSettle();
      expect(find.textContaining('Камерын зөвшөөрөл хаалттай'), findsOneWidget);
      expect(find.text('Зургийн сан'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets('Capture failure keeps the camera available for retry', (
    tester,
  ) async {
    final original = CameraPlatform.instance;
    final camera = TestCamera()..captureFails = true;
    CameraPlatform.instance = camera;
    addTearDown(() {
      CameraPlatform.instance = original;
    });
    await tester.pumpWidget(app(const RoomScanScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();
    expect(find.textContaining('Зураг авч чадсангүй.'), findsOneWidget);
    expect(find.byType(CameraPreview), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(camera.disposed, camera.created);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('No camera shows fallback and small landscape controls fit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(568, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final original = CameraPlatform.instance;
    CameraPlatform.instance = TestCamera()..available = false;
    addTearDown(() {
      CameraPlatform.instance = original;
    });
    await tester.pumpWidget(app(const RoomScanScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('Камер олдсонгүй.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets(
    'Room input fits a small display and exposes both import methods',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        app(RoomInputScreen(imageService: imageService(TestPicker()))),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Өрөөний зураг оруулах'));
      expect(find.text('Камераар скан хийх'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
