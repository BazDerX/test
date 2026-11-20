import 'package:flutter/material.dart';

import '../services/project_store.dart';
import '../services/ai_api_service.dart';
import '../models/room_design_project.dart';
import '../models/design_preferences.dart';
import '../widgets/design_screen_layout.dart';
import '../widgets/project_navigation.dart';
import '../widgets/project_image.dart';
import '../widgets/primary_button.dart';
import 'project_details_screen.dart';
import 'remote_projects_screen.dart';

Future<void> renameProject(BuildContext context, SavedDesignProject p) async {
  String name = p.name;
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Төслийн нэр'),
      content: TextFormField(
        initialValue: name,
        maxLength: 80,
        onChanged: (v) => name = v,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Болих'),
        ),
        TextButton(
          onPressed: () {
            if (name.trim().isNotEmpty) Navigator.pop(context, name.trim());
          },
          child: const Text('Хадгалах'),
        ),
      ],
    ),
  );
  if (result != null) await ProjectStore.instance.put(p.changed(name: result));
}

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key, this.api, this.embedded = false});
  final AiApiService? api;
  final bool embedded;
  @override
  State<ProjectsScreen> createState() => _ProjectsState();
}

class _ProjectsState extends State<ProjectsScreen> {
  bool savedOnly = false;
  String? error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await ProjectStore.instance.load();
    } catch (_) {
      if (mounted) setState(() => error = 'Төслүүдийг уншиж чадсангүй.');
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ProjectStore.instance,
    builder: (context, _) {
      final items = ProjectStore.instance.items
          .where((p) => !savedOnly || p.saved)
          .toList();
      return DesignScreenLayout(
        title: 'Миний төсөл',
        bottomNavigationBar: widget.embedded ? null : const ProjectNavigation(),
        children: [
          Text('${items.length} төсөл'),
          const SizedBox(height: 18),
          const Text(
            'Таны санаа, таны орон зай.',
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            label: '+ Шинэ төсөл үүсгэх',
            onPressed: () => Navigator.pushNamed(context, '/room-design'),
          ),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Бүгд'),
                selected: !savedOnly,
                onSelected: (_) => setState(() => savedOnly = false),
              ),
              ChoiceChip(
                label: const Text('Хадгалсан'),
                selected: savedOnly,
                onSelected: (_) => setState(() => savedOnly = true),
              ),
            ],
          ),
          if (error != null) Text(error!),
          if (!ProjectStore.instance.loaded && error == null)
            const CircularProgressIndicator(),
          if (ProjectStore.instance.loaded && items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Хадгалсан төсөл алга. Шинэ төсөл үүсгээрэй.'),
            ),
          ...items.map(
            (p) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProjectDetailsScreen(
                        projectId: p.id,
                        api: widget.api,
                      ),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AspectRatio(
                      aspectRatio: 1.62,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ProjectImage(path: p.previewPath),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Chip(
                              label: Text(p.saved ? '✓ Хадгалсан' : 'Ноорог'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (v) async {
                        try {
                          if (v == 'rename') {
                            await renameProject(context, p);
                          } else {
                            final yes = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Төслийг устгах уу?'),
                                content: Text(p.name),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Болих'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Устгах'),
                                  ),
                                ],
                              ),
                            );
                            if (yes == true) {
                              await ProjectStore.instance.delete(p.id);
                            }
                          }
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Хадгалж чадсангүй.'),
                              ),
                            );
                          }
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'rename',
                          child: Text('Нэр өөрчлөх'),
                        ),
                        PopupMenuItem(value: 'delete', child: Text('Устгах')),
                      ],
                    ),
                  ],
                ),
                Text(
                  '${DesignPreferences.styles[p.preferences.style]} · ${DateTime.fromMillisecondsSinceEpoch(((p.updated ?? p.created) * 1000).round()).toLocal().toString().substring(0, 16)} · ${p.placements.length} тавилга',
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => RemoteProjectsScreen(api: widget.api),
              ),
            ),
            child: const Text('Серверт хадгалсан төслүүд'),
          ),
        ],
      );
    },
  );
}
