import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/models/design_preferences.dart';
import 'package:flutter_application_1/models/room_design_project.dart';
import 'package:flutter_application_1/services/project_store.dart';
import 'package:flutter_application_1/screens/projects_screen.dart';
import 'package:flutter_application_1/screens/project_details_screen.dart';
import 'package:flutter_application_1/screens/placement_editor_screen.dart';
import 'package:flutter_application_1/screens/furniture_companies_screen.dart';
import 'package:flutter_application_1/screens/furniture_listing_screen.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:flutter_application_1/widgets/project_image.dart';

void main() {
  testWidgets('New screens fit narrow phones with enlarged text', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    ProjectStore.instance.loaded = false;
    await ProjectStore.instance.load();
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final screen in [
      const ProjectsScreen(),
      const ProjectDetailsScreen(projectId: 'missing'),
      const FurnitureCompaniesScreen(),
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
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ProjectStore.instance.loaded = false;
  });
  SavedDesignProject project() => SavedDesignProject(
    id: 'p',
    name: 'Миний өрөө',
    jobId: 'j',
    sourceImageId: 's',
    outputImageId: 'o',
    preferences: const DesignPreferences(),
    created: 1,
    originalPath: 'missing-original',
    emptyPath: 'missing-empty',
    previewPath: 'missing-preview',
    placements: [
      PlacedFurniture(
        instanceId: '1',
        furnitureId: 'cloud-sofa',
        x: .3,
        y: .6,
        scale: 1.2,
        rotation: .4,
        layerOrder: 2,
      ),
      PlacedFurniture(instanceId: '2', furnitureId: 'round-table'),
    ],
  );
  test('Projects persist paths and transforms, rename and delete', () async {
    final store = ProjectStore();
    await store.put(project());
    final restored = ProjectStore();
    await restored.load();
    expect(
      restored.items.single.placements.first.toJson(),
      project().placements.first.toJson(),
    );
    expect(restored.items.single.previewPath, 'missing-preview');
    await restored.put(restored.items.single.changed(name: 'Шинэ нэр'));
    final again = ProjectStore();
    await again.load();
    expect(again.items.single.name, 'Шинэ нэр');
    await again.delete('p');
    final empty = ProjectStore();
    await empty.load();
    expect(empty.items, isEmpty);
    final raw = (await SharedPreferences.getInstance()).getString(
      'sanaa.projects.v1',
    )!;
    expect(raw.contains('base64'), isFalse);
  });
  testWidgets(
    'Project list opens correct details, total, and placement state',
    (tester) async {
      await ProjectStore.instance.put(project());
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const ProjectsScreen()),
      );
      await tester.pumpAndSettle();
      final card = find
          .ancestor(
            of: find.byType(ProjectImage),
            matching: find.byType(InkWell),
          )
          .first;
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(find.byType(ProjectDetailsScreen), findsOneWidget);
      expect(find.text('Тооцоолсон үнэ: 1,679,000 ₮'), findsOneWidget);
      await tester.ensureVisible(find.text('Өрөөг засварлах'));
      await tester.tap(find.text('Өрөөг засварлах'));
      await tester.pumpAndSettle();
      expect(find.byType(PlacementEditorScreen), findsOneWidget);
      expect(find.byType(Positioned), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Company search, empty state and company catalog filtering', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const FurnitureCompaniesScreen(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Баянзүрх');
    await tester.pumpAndSettle();
    expect(find.text('Мод урлан'), findsOneWidget);
    expect(find.text('Гэр студи'), findsNothing);
    await tester.enterText(find.byType(TextField), 'байхгүй');
    await tester.pumpAndSettle();
    expect(find.text('Тохирох компани олдсонгүй.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Гэр');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Тавилгуудыг үзэх · 3'));
    await tester.tap(find.text('Тавилгуудыг үзэх · 3'));
    await tester.pumpAndSettle();
    expect(find.byType(FurnitureListingScreen), findsOneWidget);
    expect(find.text('Номер сандал'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
