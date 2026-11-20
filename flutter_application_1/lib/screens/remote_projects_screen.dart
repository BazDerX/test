import 'package:flutter/material.dart';

import '../models/room_design_project.dart';
import '../services/ai_api_service.dart';
import '../widgets/design_screen_layout.dart';
import 'ai_result_screen.dart';
import '../services/project_store.dart';
import 'project_details_screen.dart';

import 'package:flutter/foundation.dart';

class RemoteProjectsScreen extends StatefulWidget {
  const RemoteProjectsScreen({super.key, this.api});
  final AiApiService? api;
  @override
  State<RemoteProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<RemoteProjectsScreen> {
  AiApiService get _api => widget.api ?? AiApiService.instance;
  late Future<List<SavedDesignProject>> _projects = _api.projects();
  String? _opening;
  Future<void> _open(SavedDesignProject project) async {
    setState(() => _opening = project.id);
    try {
      final source = await _api.storedImage(project.sourceImageId);
      final generated = await _api.imageBytes(project.outputImageId);
      final job = await _api.job(project.jobId);
      final draft = RoomDesignProject(
        sourceImage: source,
        preferences: project.preferences,
      );
      draft.roomId = job.request['room_id'] as String;
      draft.sourceImageId = project.sourceImageId;
      draft.workingImageId =
          job.request['image_id'] as String? ?? project.sourceImageId;
      if (draft.workingImageId != draft.sourceImageId) {
        draft.workingImage = await _api.storedImage(draft.workingImageId!);
      }
      draft.previousJobIds.add(job.id);
      if (!kIsWeb) {
        final preview = await ProjectStore.storeImage(generated);
        if (ProjectStore.instance.find(project.id) == null) {
          await ProjectStore.instance.put(
            SavedDesignProject(
              id: project.id,
              name: project.name,
              jobId: project.jobId,
              sourceImageId: project.sourceImageId,
              outputImageId: project.outputImageId,
              preferences: project.preferences,
              created: project.created,
              roomId: draft.roomId,
              backgroundImageId: draft.workingImageId,
              originalPath: source.path,
              emptyPath: draft.workingImage.path,
              previewPath: preview,
            ),
          );
        }
        if (mounted) {
          await Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ProjectDetailsScreen(projectId: project.id, api: _api),
            ),
          );
        }
        return;
      }
      for (final id
          in (job.request['mask_ids'] as List? ?? []).cast<String>()) {
        draft.masks.add(
          SelectedObjectMask(
            id: id,
            overlay: await _api.imageBytes(id, overlay: true),
            manual: false,
          ),
        );
      }
      if (mounted) {
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => AiResultScreen(
              draft: draft,
              job: job,
              generatedBytes: generated,
              api: _api,
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is AiApiException
                  ? error.message
                  : 'Төслийг нээж чадсангүй.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  @override
  Widget build(BuildContext context) => DesignScreenLayout(
    title: 'Миний төсөл',
    children: [
      FutureBuilder<List<SavedDesignProject>>(
        future: _projects,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snapshot.error is AiApiException
                      ? (snapshot.error as AiApiException).message
                      : 'Төслүүдийг татаж чадсангүй.',
                ),
                TextButton(
                  onPressed: () => setState(() => _projects = _api.projects()),
                  child: const Text('Дахин оролдох'),
                ),
              ],
            );
          }
          final projects = snapshot.data!;
          if (projects.isEmpty) {
            return const Text('Хадгалсан төсөл одоогоор алга.');
          }
          return Column(
            children: projects
                .map(
                  (project) => Card(
                    elevation: 0,
                    child: ListTile(
                      title: Text(project.name),
                      subtitle: Text(project.preferences.summary),
                      trailing: _opening == project.id
                          ? const CircularProgressIndicator()
                          : const Icon(Icons.chevron_right),
                      onTap: _opening == null ? () => _open(project) : null,
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    ],
  );
}
