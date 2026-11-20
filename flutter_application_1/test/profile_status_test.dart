import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/models/order_request.dart';
import 'package:flutter_application_1/services/order_request_service.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/furniture_store.dart';
import 'package:flutter_application_1/services/project_store.dart';
import 'package:flutter_application_1/screens/profile_screen.dart';
import 'package:flutter_application_1/screens/profile_tools_screen.dart';
import 'package:flutter_application_1/screens/order_status_screen.dart';
import 'package:flutter_application_1/screens/order_history_screen.dart';
import 'package:flutter_application_1/theme/app_theme.dart';

OrderRequest request({
  String status = 'draft',
  String delivery = 'local_draft',
}) => OrderRequest(
  orderId: 'local-123',
  companyId: 'ger-studio',
  customerName: 'Саруул',
  phone: '99112233',
  cityDistrict: 'УБ',
  deliveryAddress: 'Хаяг',
  items: const [
    CartItem(
      furnitureId: 'cloud-sofa',
      companyId: 'ger-studio',
      quantity: 2,
      unitPrice: 1290000,
    ),
  ],
  createdAt: DateTime.utc(2026, 11, 15),
  status: status,
  deliveryStatus: delivery,
);
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ProjectStore.instance.loaded = false;
  });
  test('Draft provenance prevents false stages; explicit real statuses map correctly', () {
    expect(request(status: 'confirmed').timelineStage, -1);
    expect(
      request(status: 'Хүлээгдэж байна').statusLabel,
      'Хүсэлт түр хадгалагдсан',
    );
    for (final entry in {
      'submitted': 0,
      'reviewing': 1,
      'confirmed': 2,
      'delivering': 3,
      'delivered': 4,
      'cancelled': -1,
      'rejected': -1,
    }.entries) {
      expect(
        request(status: entry.key, delivery: 'backend').timelineStage,
        entry.value,
      );
    }
    final restored = OrderRequest.fromJson(request().toJson());
    expect(restored.subtotal, 2580000);
    expect(restored.createdAt, request().createdAt);
  });
  test(
    'Draft service normalizes status and refreshes shared history',
    () async {
      await const LocalOrderRequestService().submit(
        request(status: 'confirmed', delivery: 'backend'),
      );
      expect(OrderHistoryStore.instance.items.single.effectiveStatus, 'draft');
      expect((await LocalOrderRequestService.drafts()).single.status, 'draft');
    },
  );
  testWidgets('Profile counts, recent draft, history and timeline navigation', (
    tester,
  ) async {
    await const LocalOrderRequestService().submit(request());
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const ProfileScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.text('0 хадгалсан төсөл'), findsOneWidget);
    expect(find.text('1 захиалгын хүсэлт'), findsOneWidget);
    await tester.ensureVisible(find.text('local-123'));
    await tester.tap(find.text('local-123'));
    await tester.pumpAndSettle();
    expect(find.byType(OrderStatusScreen), findsOneWidget);
    expect(find.text('Хүсэлт түр хадгалагдсан'), findsOneWidget);
    expect(find.text('Хараахан эхлээгүй'), findsNWidgets(4));
    expect(find.text('Дууссан'), findsNothing);
    expect(find.text('Хүсэлтийн дүн: 2,580,000 ₮'), findsOneWidget);
    await tester.ensureVisible(find.text('Миний захиалгууд'));
    await tester.tap(find.text('Миний захиалгууд'));
    await tester.pumpAndSettle();
    expect(find.byType(OrderHistoryScreen), findsOneWidget);
    await tester.tap(find.text('local-123'));
    await tester.pumpAndSettle();
    expect(find.byType(OrderStatusScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Profile edit persists actual values and favorites remain synchronized',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const ProfileScreen()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Профайл засах'));
      await tester.pumpAndSettle();
      expect(find.byType(EditProfileScreen), findsOneWidget);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Саруул');
      await tester.enterText(fields.at(1), 'sar@example.mn');
      await tester.enterText(fields.at(2), '99112233');
      await tester.ensureVisible(find.text('Хадгалах'));
      await tester.tap(find.text('Хадгалах'));
      await tester.pumpAndSettle();
      expect(find.text('Саруул'), findsOneWidget);
      await AuthService.instance.loadProfile();
      expect(AuthService.instance.email, 'sar@example.mn');
      final store = FurnitureStore.instance;
      if (!store.isFavorite('cloud-sofa')) store.toggleFavorite('cloud-sofa');
      await tester.ensureVisible(find.text('Таалагдсан тавилга'));
      await tester.tap(find.text('Таалагдсан тавилга'));
      await tester.pumpAndSettle();
      expect(find.text('Үүл буйдан'), findsOneWidget);
      await tester.tap(find.byTooltip('Таалагдсанаас хасах'));
      await tester.pumpAndSettle();
      expect(find.text('Таалагдсан тавилга алга.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Profile and draft status fit narrow phones with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await const LocalOrderRequestService().submit(request());
    for (final screen in [
      const ProfileScreen(),
      const OrderStatusScreen(orderId: 'local-123'),
      const OrderHistoryScreen(),
      const EditProfileScreen(),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.6)),
            child: child!,
          ),
          home: screen,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
