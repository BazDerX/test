import 'package:flutter/material.dart';

import '../services/project_store.dart';
import '../services/furniture_store.dart';
import '../services/ai_api_service.dart';
import '../services/design_image_export.dart';
import '../models/room_design_project.dart';
import '../models/design_preferences.dart';
import '../widgets/design_screen_layout.dart';
import '../widgets/project_navigation.dart';
import '../widgets/project_image.dart';
import '../widgets/primary_button.dart';
import 'projects_screen.dart';
import 'placement_editor_screen.dart';
import 'ai_interior_screen.dart';
import 'furniture_details_screen.dart';

class ProjectDetailsScreen extends StatelessWidget {
  const ProjectDetailsScreen({super.key, required this.projectId, this.api});
  final String projectId;
  final AiApiService? api;
  Future<void> _action(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Зураг эсвэл төслийг нээж чадсангүй.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ProjectStore.instance,
    builder: (context, _) {
      final p = ProjectStore.instance.find(projectId);
      if (p == null) {
        return const DesignScreenLayout(
          title: 'Төслийн дэлгэрэнгүй',
          children: [Text('Төсөл олдсонгүй.')],
        );
      }
      final products = FurnitureStore.instance.products;
      final lines = p.placements
          .map(
            (place) => (
              place,
              products
                  .where((item) => item.id == place.furnitureId)
                  .firstOrNull,
            ),
          )
          .toList();
      final total = lines.fold<int>(0, (n, line) => n + (line.$2?.price ?? 0));
      return DesignScreenLayout(
        title: 'Төслийн дэлгэрэнгүй',
        bottomNavigationBar: const ProjectNavigation(),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 1.36,
              child: ProjectImage(path: p.previewPath),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  p.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Нэр өөрчлөх',
                onPressed: () =>
                    _action(context, () => renameProject(context, p)),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          Text(
            '✓ Хадгалсан · ${DateTime.fromMillisecondsSinceEpoch(((p.updated ?? p.created) * 1000).round()).toLocal().toString().substring(0, 16)}',
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'AI-аар засах',
            secondary: true,
            onPressed: () => _action(context, () async {
              final source = await ProjectImage.read(p.originalPath);
              final background = await ProjectImage.read(p.emptyPath);
              if (source == null) throw StateError('image');
              final draft =
                  RoomDesignProject(
                      sourceImage: source,
                      preferences: p.preferences,
                    )
                    ..roomId = p.roomId
                    ..sourceImageId = p.sourceImageId
                    ..workingImageId = p.backgroundImageId ?? p.sourceImageId;
              draft.workingImage = background ?? source;
              if (context.mounted) {
                await Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AiInteriorScreen(draft: draft, api: api),
                  ),
                );
              }
            }),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Өрөөг засварлах',
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => PlacementEditorScreen(projectId: p.id),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Төслийн тавилга · ${lines.length}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          if (lines.isEmpty)
            const Text(
              'Гараар байрлуулсан тавилга алга. AI зургийн тавилгыг каталогтой автоматаар холбоогүй.',
            ),
          ...lines.map((line) {
            final item = line.$2;
            return item == null
                ? const ListTile(title: Text('Каталогоос хасагдсан тавилга'))
                : ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        item.imagePaths.first,
                        width: 65,
                        height: 65,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(item.name),
                    subtitle: Text(
                      '${item.color} · ${item.widthCm} × ${item.depthCm} × ${item.heightCm} см\n${formatMoney(item.price)} ₮',
                    ),
                    onTap: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FurnitureDetailsScreen(product: item),
                      ),
                    ),
                  );
          }),
          const Divider(),
          Text(
            'Тооцоолсон үнэ: ${lines.any((line) => line.$2 == null) ? 'Тодорхойгүй' : '${formatMoney(total)} ₮'}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFEEE9DE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Санаагаа хуваалцах',
                  style: TextStyle(fontSize: 21),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Нийтийн холбоос хараахан дэмжигдээгүй. Зургаа хуваалцах эсвэл төхөөрөмждөө экспортлоорой.',
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                  label: 'Зургаар илгээх / хадгалах',
                  secondary: true,
                  onPressed: () => _action(context, () async {
                    final box = context.findRenderObject() as RenderBox;
                    final image = await ProjectImage.read(p.previewPath);
                    if (image == null) throw StateError('image');
                    await exportDesignImage(
                      image.bytes,
                      p.id,
                      box.localToGlobal(Offset.zero) & box.size,
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
