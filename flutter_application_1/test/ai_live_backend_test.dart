import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/room_design_project.dart';
import 'package:flutter_application_1/services/ai_api_service.dart';
import 'package:flutter_application_1/services/room_image_service.dart';

void main() {
  test(
    'Live FastAPI upload and real SAM segmentation; generation remains unavailable',
    () async {
      final api = AiApiService();
      addTearDown(api.close);
      final health = await api.health();
      expect((health['capabilities'] as Map)['segmentation'], isTrue);
      final source = File('assets/images/room_input.png');
      final draft = RoomDesignProject(
        sourceImage: RoomImage(
          path: source.absolute.path,
          bytes: await source.readAsBytes(),
        ),
      );
      await api.ensureUploaded(draft);
      expect(draft.width, 340);
      expect(draft.height, 216);
      final mask = await api.segment(draft, point: [180, 145]);
      expect(mask.manual, isFalse);
      expect(mask.overlay.length, greaterThan(100));
      expect(
        (await api.imageBytes(draft.sourceImageId!)).length,
        greaterThan(100),
      );
      await expectLater(
        api.generate(draft),
        throwsA(
          isA<AiApiException>().having(
            (error) => error.code,
            'code',
            'generation_unavailable',
          ),
        ),
      );
    },
    skip: !const bool.fromEnvironment('SANAA_LIVE_TEST'),
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
