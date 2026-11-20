import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/models/ai_generation_job.dart';
import 'package:flutter_application_1/models/design_furniture.dart';
import 'package:flutter_application_1/models/room_design_project.dart';
import 'package:flutter_application_1/services/ai_api_service.dart';
import 'package:flutter_application_1/services/room_image_service.dart';
import 'package:flutter_application_1/screens/ai_processing_screen.dart';
import 'package:flutter_application_1/screens/ai_result_screen.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:flutter_application_1/widgets/before_after_slider.dart';

class JobApi extends AiApiService {
  int submissions = 0, polls = 0, cancellations = 0;
  bool failPoll = false;
  @override
  Future<Uint8List> imageBytes(String id, {bool overlay = false}) async =>
      File('assets/images/room_input.png').readAsBytesSync();
  @override
  Future<AiGenerationJob> generate(RoomDesignProject draft) async {
    submissions++;
    return const AiGenerationJob(id: 'job', status: 'running', progress: .3);
  }

  @override
  Future<AiGenerationJob> job(String id) async {
    polls++;
    if (failPoll) throw const AiApiException('Холболт тасарсан');
    return const AiGenerationJob(
      id: 'job',
      status: 'completed',
      progress: 1,
      outputImageId: 'output',
    );
  }

  @override
  Future<void> cancel(String id) async {
    cancellations++;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('Completed server job automatically opens real output', (
    tester,
  ) async {
    final bytes = File('assets/images/room_input.png').readAsBytesSync();
    final draft = RoomDesignProject(
      sourceImage: RoomImage(path: 'room.png', bytes: bytes),
    );
    final api = JobApi();
    addTearDown(api.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AiProcessingScreen(draft: draft, api: api),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byType(AiResultScreen), findsOneWidget);
    expect(api.submissions, 1);
    expect(api.cancellations, 0);
    expect(draft.sourceImage.bytes, bytes);
    expect(tester.takeException(), isNull);
  });
  test('Catalog totals require real prices and count quantities', () {
    expect(
      DesignFurniture.total(
        DesignFurniture.fromJob(
          const AiGenerationJob(id: '1', status: 'completed'),
        ),
      ),
      isNull,
    );
    final items = DesignFurniture.fromJob(
      const AiGenerationJob(
        id: '1',
        status: 'completed',
        parameters: {
          'furniture': [
            {'name': 'Сандал', 'quantity': 2, 'unit_price_mnt': 100000},
            {'name': 'Ширээ', 'quantity': 1, 'unit_price_mnt': 300000},
          ],
        },
      ),
    )!;
    expect(items.fold<int>(0, (n, item) => n + item.quantity), 3);
    expect(DesignFurniture.total(items), 500000);
    expect(
      DesignFurniture.total([
        const DesignFurniture(name: 'Сандал', quantity: 1),
      ]),
      isNull,
    );
  });

  testWidgets('Polling failure retries existing job and cancel reaches API', (
    tester,
  ) async {
    final bytes = File('assets/images/room_input.png').readAsBytesSync();
    final draft = RoomDesignProject(
      sourceImage: RoomImage(path: 'room.png', bytes: bytes),
    );
    final api = JobApi()..failPoll = true;
    addTearDown(api.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AiProcessingScreen(draft: draft, api: api),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('Холболт тасарсан'), findsOneWidget);
    await tester.ensureVisible(find.text('Дахин оролдох'));
    await tester.tap(find.text('Дахин оролдох'));
    await tester.pump();
    expect(api.submissions, 1);
    expect(api.polls, 2);
    await tester.ensureVisible(find.text('Буцах'));
    await tester.tap(find.text('Буцах'));
    await tester.pump();
    expect(api.cancellations, 1);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('Result comparison responds to image drag at narrow width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bytes = File('assets/images/room_input.png').readAsBytesSync();
    final draft = RoomDesignProject(
      sourceImage: RoomImage(path: 'room.png', bytes: bytes),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AiResultScreen(
          draft: draft,
          job: const AiGenerationJob(
            id: '1',
            status: 'completed',
            outputImageId: 'out',
          ),
          generatedBytes: bytes,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Таны шинэ орон зай'), findsOneWidget);
    final slider = find.descendant(
      of: find.byType(BeforeAfterSlider),
      matching: find.byType(Slider),
    );
    expect(tester.widget<Slider>(slider).value, .5);
    await tester.dragFrom(
      tester.getCenter(find.byType(Image).first),
      const Offset(70, 0),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<Slider>(slider).value, greaterThan(.5));
    expect(find.text('Тодорхойгүй'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
