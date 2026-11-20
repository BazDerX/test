import 'package:flutter/material.dart';

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/services/furniture_store.dart';
import 'package:flutter_application_1/services/order_request_service.dart';
import 'package:flutter_application_1/models/order_request.dart';
import 'package:flutter_application_1/screens/shopping_cart_screen.dart';
import 'package:flutter_application_1/screens/order_request_screen.dart';
import 'package:flutter_application_1/theme/app_theme.dart';

class FailingRequests implements OrderRequestService {
  @override
  Future<RequestDelivery> submit(OrderRequest request) async =>
      throw StateError('offline');
}

class PendingRequests implements OrderRequestService {
  int calls = 0;
  final completion = Completer<RequestDelivery>();
  @override
  Future<RequestDelivery> submit(OrderRequest request) {
    calls++;
    return completion.future;
  }
}

void main() {
  testWidgets('Submission guard blocks duplicate requests while processing', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = FurnitureStore()..addToCart('cloud-sofa');
    final service = PendingRequests();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: OrderRequestScreen(
          companyId: 'ger-studio',
          store: store,
          service: service,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    for (final pair in [(0, 'Номин'), (1, '99112233'), (2, 'Хаяг')]) {
      await tester.ensureVisible(fields.at(pair.$1));
      await tester.enterText(fields.at(pair.$1), pair.$2);
    }
    await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('УБ · Хан-Уул').last);
    await tester.pumpAndSettle();
    final submit = find.text('Хүсэлт илгээх · 1,290,000 ₮');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(service.calls, 1);
    service.completion.complete(RequestDelivery.localDraft);
    await tester.pumpAndSettle();
    await store.flushCart();
    expect(tester.takeException(), isNull);
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('Cart persists quantities, company and price snapshots; decrement stops at one', () async {
    final store = FurnitureStore();
    store.addToCart('cloud-sofa');
    store.addToCart('cloud-sofa');
    store.addToCart('number-chair');
    await store.flushCart();
    final restored = FurnitureStore();
    await restored.loadCart();
    expect(restored.cartCount, 3);
    expect(restored.cartTotal, 3170000);
    expect(restored.cartItems.map((i) => i.companyId).toSet(), {
      'ger-studio',
      'mod-workshop',
    });
    restored.removeFromCart('cloud-sofa');
    restored.removeFromCart('cloud-sofa');
    expect(restored.cart['cloud-sofa'], 1);
    restored.deleteCartItem('cloud-sofa');
    await restored.flushCart();
    final again = FurnitureStore();
    await again.loadCart();
    expect(again.cartCount, 1);
  });
  test(
    'Local requests persist immutable prices and reject mixed companies',
    () async {
      final store = FurnitureStore()..addToCart('cloud-sofa');
      await store.flushCart();
      final request = OrderRequest(
        orderId: 'r',
        companyId: 'ger-studio',
        customerName: 'Номин',
        phone: '99112233',
        cityDistrict: 'УБ',
        deliveryAddress: 'Хаяг',
        items: store.cartItems,
        createdAt: DateTime.now(),
      );
      expect(
        await const LocalOrderRequestService().submit(request),
        RequestDelivery.localDraft,
      );
      store.addToCart('cloud-sofa');
      expect(
        (await LocalOrderRequestService.drafts()).single.subtotal,
        1290000,
      );
      final bad = OrderRequest(
        orderId: 'bad',
        companyId: 'other',
        customerName: 'Номин',
        phone: '99112233',
        cityDistrict: 'УБ',
        deliveryAddress: 'Хаяг',
        items: store.cartItems,
        createdAt: DateTime.now(),
      );
      await expectLater(
        const LocalOrderRequestService().submit(bad),
        throwsStateError,
      );
      await store.flushCart();
    },
  );
  testWidgets(
    'Cart quantity controls, delete and company-specific request navigation',
    (tester) async {
      final store = FurnitureStore()
        ..addToCart('cloud-sofa')
        ..addToCart('number-chair');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ShoppingCartScreen(store: store),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Тоо нэмэх').first);
      await tester.tap(find.byTooltip('Тоо нэмэх').first);
      await tester.pumpAndSettle();
      expect(store.cartCount, 3);
      await tester.ensureVisible(find.text('Гэр студи · Хүсэлт гаргах'));
      await tester.tap(find.text('Гэр студи · Хүсэлт гаргах'));
      await tester.pumpAndSettle();
      expect(find.byType(OrderRequestScreen), findsOneWidget);
      expect(find.text('Номер сандал'), findsNothing);
      expect(find.text('Үүл буйдан'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await store.flushCart();
    },
  );
  for (final failure in [false, true]) {
    testWidgets(
      'Order validation and ${failure ? 'failure' : 'local draft confirmation'}',
      (tester) async {
        final store = FurnitureStore()..addToCart('cloud-sofa');
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: OrderRequestScreen(
              companyId: 'ger-studio',
              store: store,
              service: failure
                  ? FailingRequests()
                  : const LocalOrderRequestService(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final submit = find.text('Хүсэлт илгээх · 1,290,000 ₮');
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(find.text('Овог, нэр оруулна уу.'), findsOneWidget);
        final fields = find.byType(TextFormField);
        for (final pair in [
          (0, 'Номин'),
          (1, '123'),
          (2, 'Хан-Уул, 1-р хороо'),
          (3, 'буруу'),
        ]) {
          await tester.ensureVisible(fields.at(pair.$1));
          await tester.enterText(fields.at(pair.$1), pair.$2);
        }
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(
          find.text('Монголын 8 оронтой утасны дугаар оруулна уу.'),
          findsOneWidget,
        );
        expect(find.text('Имэйл хаягаа зөв оруулна уу.'), findsOneWidget);
        await tester.ensureVisible(fields.at(1));
        await tester.enterText(fields.at(1), '9911 2233');
        await tester.ensureVisible(fields.at(3));
        await tester.enterText(fields.at(3), '');
        await tester.ensureVisible(
          find.byType(DropdownButtonFormField<String>),
        );
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('УБ · Хан-Уул').last);
        await tester.pumpAndSettle();
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pumpAndSettle();
        if (failure) {
          expect(
            find.text('Хүсэлтийг хадгалж чадсангүй. Дахин оролдоно уу.'),
            findsOneWidget,
          );
          expect(await LocalOrderRequestService.drafts(), isEmpty);
        } else {
          expect((await LocalOrderRequestService.drafts()).length, 1);
          expect(find.textContaining('Хүсэлт түр хадгалагдлаа'), findsWidgets);
          expect(store.cartCount, 1);
        }
        expect(find.text('Хүсэлт амжилттай илгээгдлээ.'), findsNothing);
        expect(tester.takeException(), isNull);
        await store.flushCart();
      },
    );
  }
  testWidgets('Cart and request fit narrow viewport and keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = FurnitureStore()..addToCart('cloud-sofa');
    for (final screen in [
      ShoppingCartScreen(store: store),
      OrderRequestScreen(companyId: 'ger-studio', store: store),
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
    tester.view.viewInsets = const FakeViewPadding(bottom: 250);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Хүсэлт илгээх · 1,290,000 ₮'));
    expect(tester.takeException(), isNull);
    await store.flushCart();
  });
}
