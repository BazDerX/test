import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/models/furniture.dart';
import 'package:flutter_application_1/services/furniture_store.dart';
import 'package:flutter_application_1/screens/furniture_listing_screen.dart';
import 'package:flutter_application_1/screens/furniture_filter_screen.dart';
import 'package:flutter_application_1/screens/furniture_details_screen.dart';
import 'package:flutter_application_1/theme/app_theme.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'Catalog combines search, price, dimensions, material, color and company',
    () {
      final store = FurnitureStore();
      addTearDown(() async {
        await store.flushCart();
        store.dispose();
      });
      expect(store.visibleProducts.length, 4);
      store.setQuery('ҮҮЛ');
      expect(store.visibleProducts.single.id, 'cloud-sofa');
      store.setQuery('');
      store.applyFilters(
        const FurnitureFilters(
          minPrice: 200000,
          maxPrice: 600000,
          maxWidth: 85,
          maxDepth: 85,
          maxHeight: 85,
          materials: {'Мод'},
          colors: {'Модон'},
          company: 'Гэр студи',
        ),
      );
      expect(store.visibleProducts.single.id, 'round-table');
      store.applyFilters(
        const FurnitureFilters(
          category: 'Сандал',
          materials: {'Даавуу'},
          maxHeight: 80,
        ),
      );
      expect(store.visibleProducts.single.id, 'number-chair');
      store.applyFilters(const FurnitureFilters(maxDepth: 30));
      expect(store.visibleProducts, isEmpty);
      store.applyFilters(const FurnitureFilters(only3D: true));
      expect(store.visibleProducts, isEmpty);
      expect(
        const FurnitureFilters(only3D: true).matches(
          const Furniture(
            id: 'model',
            name: 'Загвар',
            description: '',
            price: 1,
            category: 'Сандал',
            company: 'Урлан',
            imagePaths: [],
            widthCm: 1,
            depthCm: 1,
            heightCm: 1,
            material: 'Мод',
            color: 'Модон',
            warrantyMonths: 1,
            has3DModel: true,
            model3DPath: 'assets/models/chair.glb',
          ),
        ),
        isTrue,
      );
      store.applyFilters(const FurnitureFilters());
      store.setSort(FurnitureSort.lowestPrice);
      expect(store.visibleProducts.first.id, 'ray-lamp');
      store.setSort(FurnitureSort.highestPrice);
      expect(store.visibleProducts.first.id, 'cloud-sofa');
      store.toggleFavorite('cloud-sofa');
      expect(store.favoriteCount, 1);
      store.toggleFavorite('cloud-sofa');
      expect(store.favoriteCount, 0);
      store.addToCart('cloud-sofa');
      store.addToCart('cloud-sofa');
      store.addToCart('round-table');
      expect(store.cartCount, 3);
      expect(store.cartTotal, 2969000);
      store.removeFromCart('cloud-sofa');
      expect(store.cartCount, 2);
    },
  );

  testWidgets(
    'Listing opens correct details and synchronizes favorite and cart',
    (tester) async {
      final store = FurnitureStore();
      addTearDown(store.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: FurnitureListingScreen(store: store),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Үүл буйдан'));
      await tester.tap(find.text('Үүл буйдан'));
      await tester.pumpAndSettle();
      expect(find.byType(FurnitureDetailsScreen), findsOneWidget);
      expect(find.text('180 × 86 × 76 см'), findsOneWidget);
      await tester.tap(find.byTooltip('Хадгалах').last);
      await tester.pump();
      expect(store.isFavorite('cloud-sofa'), isTrue);
      await tester.ensureVisible(find.text('Сагсанд нэмэх'));
      await tester.tap(find.text('Сагсанд нэмэх'));
      await tester.pump();
      expect(find.text('Сагс · 1'), findsOneWidget);
      await tester.ensureVisible(find.text('3D загварыг эргүүлж үзэх'));
      await tester.tap(find.text('3D загварыг эргүүлж үзэх'));
      await tester.pumpAndSettle();
      expect(find.text('3D загвар бэлэн болоогүй байна.'), findsOneWidget);
      await tester.tap(find.text('Ойлголоо'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Сагс · 1'), findsOneWidget);
      expect(find.byTooltip('Хадгалснаас хасах'), findsOneWidget);
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'байхгүй');
      await tester.pumpAndSettle();
      expect(find.text('Тохирох тавилга олдсонгүй.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Filters apply, retain values, reject inverted prices and reset',
    (tester) async {
      final store = FurnitureStore();
      addTearDown(store.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: FurnitureListingScreen(store: store),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Шүүх'));
      await tester.pumpAndSettle();
      expect(find.byType(FurnitureFilterScreen), findsOneWidget);
      await tester.tap(find.text('Сандал'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('1 тавилга үзэх'));
      await tester.tap(find.text('1 тавилга үзэх'));
      await tester.pumpAndSettle();
      expect(store.filters.category, 'Сандал');
      expect(find.text('Номер сандал'), findsOneWidget);
      expect(find.text('Үүл буйдан'), findsNothing);
      await tester.tap(find.text('Шүүх · 1'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Сандал'))
            .selected,
        isTrue,
      );
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '600000');
      await tester.enterText(fields.at(1), '100000');
      await tester.pump();
      await tester.ensureVisible(find.text('0 тавилга үзэх'));
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, '0 тавилга үзэх'),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(find.text('Бүх шүүлтүүрийг цэвэрлэх'));
      await tester.tap(find.text('Бүх шүүлтүүрийг цэвэрлэх'));
      await tester.pumpAndSettle();
      expect(find.text('4 тавилга үзэх'), findsOneWidget);
      await tester.tap(find.text('4 тавилга үзэх'));
      await tester.pumpAndSettle();
      expect(store.filters.activeCount, 0);
      expect(tester.takeException(), isNull);
    },
  );

  for (final scale in [1.0, 1.6]) {
    testWidgets('Furniture screens fit 320px at text scale $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = FurnitureStore();
      addTearDown(store.dispose);
      for (final screen in [
        FurnitureListingScreen(store: store),
        FurnitureFilterScreen(store: store),
        FurnitureDetailsScreen(product: store.products.first, store: store),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
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
}
