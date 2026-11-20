import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/screens/home_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('Registration validates, accepts terms and greets the user', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const SanaaApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Бүртгүүлэх'));
    await tester.tap(find.text('Бүртгүүлэх'));
    await tester.pumpAndSettle();
    final submit = find.widgetWithText(FilledButton, 'Бүртгэл үүсгэх');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Үйлчилгээний нөхцөлийг зөвшөөрнө үү.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Саруул');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'saruul@example.mn',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'Sanaa123');
    await tester.ensureVisible(find.byTooltip('Нууц үг харуулах'));
    await tester.tap(find.byTooltip('Нууц үг харуулах'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      isFalse,
    );
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Сайн уу, Саруул 👋'), findsOneWidget);
    await tester.tap(find.text('Тавилга'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Хадгалах').first);
    await tester.pump();
    expect(find.byTooltip('Хадгалснаас хасах'), findsOneWidget);
    await tester.tap(find.text('Профайл'));
    await tester.pumpAndSettle();
    expect(find.text('Хадгалсан тавилга: 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mock login reaches home', (tester) async {
    await tester.pumpWidget(const SanaaApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Нэвтрэх'));
    await tester.tap(find.text('Нэвтрэх'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '99112233');
    await tester.enterText(find.byType(TextFormField).last, 'demo');
    final submit = find.widgetWithText(FilledButton, 'Нэвтрэх');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Registration fits a small viewport with keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const SanaaApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Бүртгүүлэх'));
    await tester.tap(find.text('Бүртгүүлэх'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Бүртгэл үүсгэх'),
    );
    expect(tester.takeException(), isNull);
  });
}
