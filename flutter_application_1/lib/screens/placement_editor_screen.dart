import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../models/room_design_project.dart';
import '../services/project_store.dart';
import '../services/furniture_store.dart';
import '../widgets/project_image.dart';
import '../widgets/design_screen_layout.dart';
import '../widgets/primary_button.dart';
import 'furniture_details_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

class PlacementEditorScreen extends StatefulWidget {
  const PlacementEditorScreen({super.key, required this.projectId});
  final String projectId;
  @override
  State<PlacementEditorScreen> createState() => _PlacementState();
}

class _PlacementState extends State<PlacementEditorScreen> {
  final canvas = GlobalKey();
  late final project = ProjectStore.instance.find(widget.projectId)!;
  late final List<PlacedFurniture> placements = project.placements
      .map((p) => PlacedFurniture.fromJson(p.toJson()))
      .toList();
  PlacedFurniture? selected;
  bool busy = false;
  bool showTips = true;
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance()
        .then((prefs) {
          if (mounted) {
            setState(() => showTips = prefs.getBool('sanaa.help.tips') ?? true);
          }
        })
        .catchError((Object _) {});
  }

  @override
  Widget build(BuildContext context) => DesignScreenLayout(
    title: 'Өрөөг засварлах',
    children: [
      if (showTips)
        const Text(
          '2D эвлүүлэг · Тавилгыг чирч байрлуулаад хэмжээ, эргэлтийг тохируулна уу. Каталогийн зураг нь 3D загвар биш.',
        ),
      const SizedBox(height: 12),
      RepaintBoundary(
        key: canvas,
        child: AspectRatio(
          aspectRatio: 1.2,
          child: LayoutBuilder(
            builder: (context, size) => Stack(
              clipBehavior: Clip.hardEdge,
              fit: StackFit.expand,
              children: [
                ProjectImage(path: project.emptyPath ?? project.previewPath),
                ...([
                  ...placements,
                ]..sort((a, b) => a.layerOrder.compareTo(b.layerOrder))).map((
                  place,
                ) {
                  final item = FurnitureStore.instance.products
                      .where((item) => item.id == place.furnitureId)
                      .firstOrNull;
                  if (item == null) return const SizedBox();
                  return Positioned(
                    left: place.x * size.maxWidth - 40,
                    top: place.y * size.maxHeight - 40,
                    child: GestureDetector(
                      onTap: () => setState(() => selected = place),
                      onPanUpdate: (details) => setState(() {
                        selected = place;
                        place.x = (place.x + details.delta.dx / size.maxWidth)
                            .clamp(0, 1);
                        place.y = (place.y + details.delta.dy / size.maxHeight)
                            .clamp(0, 1);
                      }),
                      child: Transform.rotate(
                        angle: place.rotation,
                        child: Transform.scale(
                          scale: place.scale,
                          child: Image.asset(
                            item.imagePaths.first,
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      Wrap(
        spacing: 8,
        children: FurnitureStore.instance.products
            .map(
              (item) => ActionChip(
                label: Text('+ ${item.name}'),
                onPressed: () => setState(() {
                  selected = PlacedFurniture(
                    instanceId: DateTime.now().microsecondsSinceEpoch
                        .toString(),
                    furnitureId: item.id,
                    layerOrder: placements.length,
                  );
                  placements.add(selected!);
                }),
              ),
            )
            .toList(),
      ),
      if (selected != null) ...[
        TextButton(
          onPressed: () {
            final item = FurnitureStore.instance.products
                .where((p) => p.id == selected!.furnitureId)
                .firstOrNull;
            if (item != null) {
              Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => FurnitureDetailsScreen(product: item),
                ),
              );
            }
          },
          child: const Text('Тавилгын дэлгэрэнгүй / Сагсанд нэмэх'),
        ),
        const Text('Хэмжээ'),
        Slider(
          value: selected!.scale,
          min: .3,
          max: 2,
          onChanged: (v) => setState(() => selected!.scale = v),
        ),
        const Text('Эргэлт'),
        Slider(
          value: selected!.rotation,
          min: -3.1416,
          max: 3.1416,
          onChanged: (v) => setState(() => selected!.rotation = v),
        ),
        Wrap(
          children: [
            TextButton(
              onPressed: () => setState(() {
                selected!.layerOrder =
                    placements.fold<int>(
                      0,
                      (n, p) => p.layerOrder > n ? p.layerOrder : n,
                    ) +
                    1;
              }),
              child: const Text('Урд гаргах'),
            ),
            TextButton(
              onPressed: () => setState(() {
                placements.remove(selected);
                selected = null;
              }),
              child: const Text('Тавилгыг хасах'),
            ),
          ],
        ),
      ],
      PrimaryButton(
        label: 'Төслийг хадгалах',
        loading: busy,
        onPressed: () async {
          setState(() => busy = true);
          try {
            await WidgetsBinding.instance.endOfFrame;
            if (!mounted) return;
            final boundary =
                canvas.currentContext!.findRenderObject()
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            image.dispose();
            final path = await ProjectStore.storeImage(
              bytes!.buffer.asUint8List(),
            );
            await ProjectStore.instance.put(
              project.changed(previewPath: path, placements: placements),
            );
            if (context.mounted) Navigator.pop(context);
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Хадгалж чадсангүй. Дахин оролдоно уу.'),
                ),
              );
            }
          } finally {
            if (mounted) setState(() => busy = false);
          }
        },
      ),
    ],
  );
}
