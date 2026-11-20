import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/screens/room_input_screen.dart';
import 'package:flutter_application_1/services/room_image_service.dart';
import 'package:flutter_application_1/theme/app_theme.dart';

class _LayoutImages extends RoomImageService {
  @override
  Future<RoomImage?> recoverLostImage() async => null;
}

void main() {
  testWidgets('Room input reference layout at phone size', (tester) async {
    if (const bool.fromEnvironment('ROOM_SCREENSHOTS')) {
      const fonts = String.fromEnvironment('FLUTTER_FONT_DIR');
      await tester.runAsync(() async {
        final roboto = FontLoader('Roboto');
        for (final weight in ['regular', 'medium', 'bold']) {
          roboto.addFont(
            File('$fonts/roboto-$weight.ttf')
                .readAsBytes()
                .then(ByteData.sublistView),
          );
        }
        await roboto.load();
        await (FontLoader('Ahem')..addFont(
              File('$fonts/roboto-regular.ttf')
                  .readAsBytes()
                  .then(ByteData.sublistView),
            ))
            .load();
        await (FontLoader('MaterialIcons')..addFont(
              File('$fonts/materialicons-regular.otf')
                  .readAsBytes()
                  .then(ByteData.sublistView),
            ))
            .load();
      });
    }
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 44, bottom: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    const boundary = ValueKey('room-input-render');
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          initialRoute: '/room',
          routes: {
            '/': (_) => const SizedBox(),
            '/room': (_) => RoomInputScreen(imageService: _LayoutImages()),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/images/room_input.png'),
        tester.element(find.byType(RoomInputScreen)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    if (const bool.fromEnvironment('ROOM_SCREENSHOTS')) {
      await expectLater(
        find.byKey(boundary),
        matchesGoldenFile('../build/room_input_preview.png'),
      );
    }
  });
}
