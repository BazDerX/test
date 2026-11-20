import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/models/design_preferences.dart';
import 'package:flutter_application_1/models/room_design_project.dart';
import 'package:flutter_application_1/services/ai_api_service.dart';
import 'package:flutter_application_1/services/design_draft_store.dart';
import 'package:flutter_application_1/services/room_image_service.dart';
import 'package:flutter_application_1/screens/style_selection_screen.dart';
import 'package:flutter_application_1/screens/room_confirmation_screen.dart';
import 'package:flutter_application_1/widgets/object_mask_editor.dart';
import 'package:flutter_application_1/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<RoomDesignProject> draft() async => RoomDesignProject(
    sourceImage: RoomImage(
      path: File('assets/images/room_input.png').absolute.path,
      bytes: await File('assets/images/room_input.png').readAsBytes(),
    ),
  );

  test('Cover touch mapping accounts for centered source crop', () {
    final mapping = ImageCoverTransform(
      const Size(1200, 600),
      const Size(300, 300),
    );
    expect(mapping.toImage(Offset.zero), const Offset(300, 0));
    expect(mapping.toImage(const Offset(150, 150)), const Offset(600, 300));
    expect(mapping.toImage(const Offset(300, 300)), const Offset(900, 599));
    final portrait = ImageCoverTransform(
      const Size(600, 1200),
      const Size(300, 300),
    );
    expect(portrait.toImage(Offset.zero), const Offset(0, 300));
  });

  test(
    'Draft round trip preserves image, preferences and server identifiers',
    () async {
      final original = await draft();
      original.preferences = const DesignPreferences(
        roomType: 'bedroom',
        style: 'classic',
        palette: 'sage',
        budget: 3500000,
        prompt: 'A calm bedroom',
      );
      original.roomId = 'room-id';
      original.sourceImageId = 'source-id';
      original.workingImageId = 'source-id';
      await DesignDraftStore.save(original);
      final restored = await DesignDraftStore.load();
      expect(restored!.preferences.toJson(), original.preferences.toJson());
      expect(restored.sourceImage.bytes, original.sourceImage.bytes);
      expect(restored.roomId, 'room-id');
    },
  );

  test(
    'API uses bearer auth and preserves structured unavailable errors',
    () async {
      final api = AiApiService(
        baseUrl: 'http://127.0.0.1:8000',
        token: 'test',
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer test');
          return http.Response(
            jsonEncode({
              'error': {
                'code': 'generation_unavailable',
                'message': 'Загвар холбогдоогүй.',
              },
            }),
            503,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(api.close);
      await expectLater(
        api.health(),
        throwsA(
          isA<AiApiException>()
              .having((error) => error.status, 'status', 503)
              .having((error) => error.code, 'code', 'generation_unavailable'),
        ),
      );
    },
  );

  testWidgets('Manual brush mask uses image coordinates and supports erasing', (
    tester,
  ) async {
    final controller = ObjectMaskEditorController()
      ..imageSize = const Size(100, 100);
    controller.strokes.add(
      MaskStroke(
        erase: false,
        width: 20,
        points: [const Offset(20, 50), const Offset(80, 50)],
      ),
    );
    controller.strokes.add(
      MaskStroke(erase: true, width: 10, points: [const Offset(50, 50)]),
    );
    final data = await tester.runAsync(() async {
      final image = await controller.renderMask();
      try {
        return await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      } finally {
        image.dispose();
      }
    });
    int red(int x, int y) => data!.getUint8((y * 100 + x) * 4);
    expect(red(25, 50), 255);
    expect(red(50, 50), 0);
    expect(red(0, 0), 0);
    controller.dispose();
  });

  testWidgets('Confirmation shows actual room and neutral quality guidance', (
    tester,
  ) async {
    final room = await tester.runAsync(draft);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: RoomConfirmationScreen(image: room!.sourceImage),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();
    expect(find.text('Ямар өрөө вэ?'), findsOneWidget);
    expect(find.textContaining('автоматаар таниагүй'), findsOneWidget);
    await tester.ensureVisible(find.text('Унтлагын өрөө'));
    await tester.tap(find.text('Унтлагын өрөө'));
    await tester.pump();
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Унтлагын өрөө'))
          .selected,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Style, palette and budget change typed preferences', (
    tester,
  ) async {
    final room = await tester.runAsync(draft);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: StyleSelectionScreen(draft: room!),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Сонгодог'));
    await tester.tap(find.text('Сонгодог'));
    await tester.pumpAndSettle();
    expect(room.preferences.style, 'classic');
    await tester.ensureVisible(find.bySemanticsLabel('Ойн ногоон'));
    await tester.tap(find.bySemanticsLabel('Ойн ногоон'));
    await tester.pumpAndSettle();
    expect(room.preferences.palette, 'forest');
    await tester.ensureVisible(find.byType(Slider));
    await tester.drag(find.byType(Slider), const Offset(60, 0));
    await tester.pumpAndSettle();
    expect(room.preferences.budget, isNot(2000000));
    expect(tester.takeException(), isNull);
  });
}
