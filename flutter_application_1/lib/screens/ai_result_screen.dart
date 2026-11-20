import 'package:flutter/foundation.dart';

import '../services/project_store.dart';

import 'package:flutter/material.dart';

import '../models/ai_generation_job.dart';
import '../models/design_preferences.dart';
import '../models/design_furniture.dart';
import '../models/room_design_project.dart';
import '../services/ai_api_service.dart';
import '../services/design_image_export.dart';
import '../theme/app_theme.dart';
import '../widgets/design_screen_layout.dart';
import '../widgets/before_after_slider.dart';
import '../widgets/primary_button.dart';
import '../widgets/room_progress_indicator.dart';
import '../widgets/bottom_navigation.dart';
import 'ai_interior_screen.dart';
import 'design_furniture_screen.dart';
import 'home_screen.dart';
import 'ai_processing_screen.dart';
import 'projects_screen.dart';

class AiResultScreen extends StatefulWidget {
  const AiResultScreen({
    super.key,
    required this.draft,
    required this.job,
    required this.generatedBytes,
    this.api,
  });
  final RoomDesignProject draft;
  final AiGenerationJob job;
  final Uint8List generatedBytes;
  final AiApiService? api;
  @override
  State<AiResultScreen> createState() => _AiResultScreenState();
}

class _AiResultScreenState extends State<AiResultScreen> {
  AiApiService get _api => widget.api ?? AiApiService.instance;
  bool _busy = false, _saved = false;
  String get _name =>
      widget.job.parameters['room_name'] as String? ??
      'Миний ${widget.draft.preferences.roomType == 'living' ? 'зочны' : 'унтлагын'} өрөө';
  List<DesignFurniture>? get _furniture => DesignFurniture.fromJob(widget.job);
  int? get _total => DesignFurniture.total(_furniture);

  void _viewFurniture() => Navigator.push<void>(
    context,
    MaterialPageRoute(builder: (_) => DesignFurnitureScreen(items: _furniture)),
  );

  void _edit() => Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (_) => AiInteriorScreen(draft: widget.draft, api: _api),
    ),
  );
  void _error(Object error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is AiApiException
                ? error.message
                : 'Үйлдэл амжилтгүй боллоо.',
          ),
        ),
      );
    }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final saved = await _api.saveProject(widget.job.id, _name);
      if (!kIsWeb) {
        final preview = await ProjectStore.storeImage(widget.generatedBytes);
        await ProjectStore.instance.put(
          SavedDesignProject(
            id: saved.id,
            name: _name,
            jobId: widget.job.id,
            sourceImageId: saved.sourceImageId,
            outputImageId: saved.outputImageId,
            preferences: widget.draft.preferences,
            created: saved.created,
            roomId: widget.draft.roomId,
            backgroundImageId: widget.draft.workingImageId,
            originalPath: widget.draft.sourceImage.path,
            emptyPath: widget.draft.workingImage.path,
            previewPath: preview,
          ),
        );
      }
      if (mounted) {
        setState(() => _saved = true);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Төсөл хадгалагдлаа.')));
      }
    } catch (error) {
      _error(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final box = context.findRenderObject() as RenderBox;
      await exportDesignImage(
        widget.generatedBytes,
        widget.job.outputImageId!,
        box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (error) {
      _error(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _history(String jobId) async {
    setState(() => _busy = true);
    try {
      final job = await _api.job(jobId);
      if (job.status != 'completed' || job.outputImageId == null) {
        throw AiApiException(job.error ?? 'Энэ ажил дуусаагүй байна.');
      }
      final bytes = await _api.imageBytes(job.outputImageId!);
      if (mounted) {
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => AiResultScreen(
              draft: widget.draft,
              job: job,
              generatedBytes: bytes,
              api: _api,
            ),
          ),
        );
      }
    } catch (error) {
      _error(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => DesignScreenLayout(
    title: 'Таны шинэ орон зай',
    bottomNavigationBar: SanaaBottomNavigation(
      selected: 2,
      onSelected: (index) {
        if (_busy || index == 2) return;
        if (index == 1) {
          _viewFurniture();
          return;
        }
        if (index == 3) {
          Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => ProjectsScreen(api: _api)),
          );
          return;
        }
        Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen(initialTab: index)),
        );
      },
    ),
    children: [
      const RoomProgressIndicator(step: 4),
      const SizedBox(height: 24),
      BeforeAfterSlider(
        before: widget.draft.sourceImage.bytes,
        after: widget.generatedBytes,
      ),
      const SizedBox(height: 16),
      Text(
        _name,
        style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 16),
      Text(
        '${DesignPreferences.styles[widget.draft.preferences.style] ?? widget.draft.preferences.style} · '
        '${DesignPreferences.palettes[widget.draft.preferences.palette] ?? widget.draft.preferences.palette}',
        style: const TextStyle(
          color: AppTheme.muted,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        widget.job.parameters['description'] as String? ??
            widget.job.request['prompt'] as String? ??
            widget.draft.preferences.prompt,
      ),
      const SizedBox(height: 12),
      const Text(
        'AI дүрслэл нь бодит бүтээгдэхүүний үнийн санал биш. Архитектурын бүтэц өөрчлөгдөх боломжтой.',
        style: TextStyle(fontSize: 11, color: AppTheme.muted),
      ),
      const SizedBox(height: 20),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_furniture == null ? 'Тавилгын тоо тодорхойгүй' : '${_furniture!.fold<int>(0, (sum, item) => sum + item.quantity)} тавилга'} · '
              '${DesignPreferences.styles[widget.draft.preferences.style] ?? widget.draft.preferences.style}',
              style: const TextStyle(fontSize: 12, color: AppTheme.muted),
            ),
            const Divider(color: AppTheme.border, height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Тооцоолсон үнэ',
                    style: TextStyle(color: AppTheme.muted),
                  ),
                ),
                Flexible(
                  child: Text(
                    _total == null
                        ? 'Тодорхойгүй'
                        : '${formatMoney(_total!)} ₮',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _total == null
                  ? 'Үнэ, хэмнэлтийг тооцох тавилгын мэдээлэл ирээгүй.'
                  : widget.draft.preferences.budget >= _total!
                  ? 'Төсвөөс ${formatMoney(widget.draft.preferences.budget - _total!)} ₮ хэмнэсэн'
                  : 'Төсвөөс ${formatMoney(_total! - widget.draft.preferences.budget)} ₮ хэтэрсэн',
              style: const TextStyle(fontSize: 12, color: AppTheme.green),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: PrimaryButton(
              label: 'Дахин үүсгэх',
              secondary: true,
              onPressed: _busy
                  ? null
                  : () {
                      widget.draft.preferences = widget.draft.preferences
                          .copyWith(seed: widget.draft.preferences.seed + 1);
                      Navigator.pushReplacement<void, void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AiProcessingScreen(
                            draft: widget.draft,
                            api: _api,
                          ),
                        ),
                      );
                    },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: PrimaryButton(
              label: 'Засах',
              secondary: true,
              onPressed: _busy ? null : _edit,
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      PrimaryButton(
        label: _saved ? 'Хадгалсан' : 'Төслөө хадгалах',
        loading: _busy,
        onPressed: _saved ? null : _save,
      ),
      const SizedBox(height: 12),
      PrimaryButton(
        label:
            'Тавилгуудыг үзэх${_furniture == null ? '' : ' · ${_furniture!.fold<int>(0, (sum, item) => sum + item.quantity)}'}',
        secondary: true,
        onPressed: _busy ? null : _viewFurniture,
      ),
      TextButton.icon(
        onPressed: _busy ? null : _export,
        icon: const Icon(Icons.download_outlined),
        label: const Text('Зураг татах'),
      ),
      TextButton.icon(
        onPressed: _busy
            ? null
            : () => Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => ProjectsScreen(api: _api)),
              ),
        icon: const Icon(Icons.folder_outlined),
        label: const Text('Миний төсөл рүү'),
      ),
      TextButton(
        onPressed: () =>
            Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false),
        child: const Text('Нүүр рүү'),
      ),
      if (widget.draft.previousJobIds.length > 1) ...[
        const Text(
          'Өмнөх үр дүн',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        Wrap(
          spacing: 8,
          children: widget.draft.previousJobIds
              .where((id) => id != widget.job.id)
              .map(
                (id) => ActionChip(
                  label: Text(
                    'Үр дүн ${widget.draft.previousJobIds.indexOf(id) + 1}',
                  ),
                  onPressed: _busy ? null : () => _history(id),
                ),
              )
              .toList(),
        ),
      ],
    ],
  );
}
