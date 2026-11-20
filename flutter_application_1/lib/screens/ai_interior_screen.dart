import 'dart:ui' as ui;
import 'dart:async';

import 'package:flutter/material.dart';

import '../models/room_design_project.dart';
import '../services/ai_api_service.dart';
import '../services/design_draft_store.dart';
import '../theme/app_theme.dart';
import '../widgets/design_screen_layout.dart';
import '../widgets/object_mask_editor.dart';
import '../widgets/primary_button.dart';
import '../widgets/room_progress_indicator.dart';
import 'ai_processing_screen.dart';
import '../services/project_store.dart';
import 'placement_editor_screen.dart';

class AiInteriorScreen extends StatefulWidget {
  const AiInteriorScreen({super.key, required this.draft, this.api});
  final RoomDesignProject draft;
  final AiApiService? api;
  @override
  State<AiInteriorScreen> createState() => _AiInteriorScreenState();
}

class _AiInteriorScreenState extends State<AiInteriorScreen> {
  AiApiService get _api => widget.api ?? AiApiService.instance;
  final _editor = ObjectMaskEditorController();
  late final _prompt = TextEditingController(
    text: widget.draft.preferences.prompt,
  );
  MaskTool _tool = MaskTool.brush;
  bool _busy = true, _segmentation = false;
  String? _status;
  Timer? _saveDelay;
  RoomDesignProject get _draft => widget.draft;
  @override
  void initState() {
    super.initState();
    _prompt.addListener(() {
      _draft.preferences = _draft.preferences.copyWith(prompt: _prompt.text);
      _saveDelay?.cancel();
      _saveDelay = Timer(const Duration(milliseconds: 600), _persist);
    });
    _initialize();
  }

  Future<void> _persist() async {
    try {
      await DesignDraftStore.save(_draft);
    } catch (_) {
      if (mounted) {
        setState(
          () => _status =
              'Ноорог хадгалж чадсангүй. Төхөөрөмжийн зайг шалгана уу.',
        );
      }
    }
  }

  @override
  void dispose() {
    _saveDelay?.cancel();
    unawaited(_persist());
    _prompt.dispose();
    _editor.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final codec = await ui.instantiateImageCodec(_draft.workingImage.bytes);
      try {
        final frame = await codec.getNextFrame();
        _draft.width = frame.image.width;
        _draft.height = frame.image.height;
        frame.image.dispose();
      } finally {
        codec.dispose();
      }
      if (mounted) setState(() {});
      final health = await _api.health();
      _segmentation = (health['capabilities'] as Map?)?['segmentation'] == true;
      await _api.ensureUploaded(_draft);
      if (_segmentation) _tool = MaskTool.point;
      _status = _segmentation
          ? 'Объект дээр дарж эсвэл хүрээлж сонгоно уу.'
          : 'SAM 2 боломжгүй · Гараар маск зурах горим.';
      await DesignDraftStore.save(_draft);
    } catch (error) {
      _status = error is AiApiException
          ? error.message
          : 'Зураг эсвэл серверийг нээж чадсангүй. Дахин оролдоно уу.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _show(Object error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is AiApiException
                ? error.message
                : 'Үйлдэл амжилтгүй боллоо. Дахин оролдоно уу.',
          ),
        ),
      );
    }
  }

  Future<void> _select({Offset? point, Rect? box}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final mask = await _api.segment(
        _draft,
        point: point == null ? null : [point.dx, point.dy],
        box: box == null ? null : [box.left, box.top, box.right, box.bottom],
      );
      if (!mounted) return;
      setState(() => _draft.masks.add(mask));
      await _persist();
      _editor.box = null;
      _editor.changed();
    } catch (error) {
      _show(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _acceptManual() async {
    if (_busy || (_editor.strokes.isEmpty && _editor.baseMask == null)) return;
    setState(() => _busy = true);
    try {
      final mask = await _editor.renderMask();
      try {
        final data = await mask.toByteData(format: ui.ImageByteFormat.png);
        final selection = await _api.uploadMask(
          _draft,
          data!.buffer.asUint8List(),
        );
        if (mounted) setState(() => _draft.masks.add(selection));
        await _persist();
        if (mounted) _editor.clear();
      } finally {
        mask.dispose();
      }
    } catch (error) {
      _show(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    setState(() => _busy = true);
    try {
      await _api.removeFurniture(_draft);
      await DesignDraftStore.save(_draft);
      _editor.clear();
    } catch (error) {
      _show(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _correct(int index) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final mask = _draft.masks[index];
      await _editor.loadBase(await _api.imageBytes(mask.id));
      if (mounted) {
        setState(() {
          _draft.masks.removeAt(index);
          _tool = MaskTool.brush;
        });
      }
    } catch (error) {
      _show(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _undoRemoval() {
    setState(() {
      _draft.workingImage = _draft.sourceImage;
      _draft.workingImageId = _draft.sourceImageId;
      _draft.masks.clear();
      _draft.acceptedMaskIds.clear();
    });
    _editor.clear();
    DesignDraftStore.save(_draft).catchError((Object error) => _show(error));
  }

  Future<void> _generate() async {
    if (_prompt.text.trim().length < 5) {
      _show(
        const AiApiException(
          'Хүссэн тохижуулалтаа 5-аас дээш тэмдэгтээр тайлбарлана уу.',
        ),
      );
      return;
    }
    if (_editor.strokes.isNotEmpty || _editor.baseMask != null) {
      _show(
        const AiApiException(
          'Гараар зурсан маскаа эхлээд батлах эсвэл арилгана уу.',
        ),
      );
      return;
    }
    _draft.preferences = _draft.preferences.copyWith(
      prompt: _prompt.text.trim(),
    );
    try {
      await DesignDraftStore.save(_draft);
    } catch (error) {
      _show(error);
      return;
    }
    if (!mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => AiProcessingScreen(draft: _draft, api: _api),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => DesignScreenLayout(
    title: 'AI-аар тохижуулах',
    children: [
      const RoomProgressIndicator(step: 3),
      const SizedBox(height: 24),
      const Text(
        '1. Хуучин тавилгаа сонгох',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 10),
      const Text(
        'Зураг дээрээс арилгах тавилгаа сонгоорой. Хана, цонхыг масканд бүү оруулаарай.',
        style: TextStyle(fontSize: 12, color: AppTheme.muted),
      ),
      const SizedBox(height: 12),
      if (_draft.width > 0 && _draft.height > 0)
        ObjectMaskEditor(
          image: _draft.workingImage,
          width: _draft.width,
          height: _draft.height,
          controller: _editor,
          tool: _tool,
          masks: _draft.masks,
          enabled: !_busy,
          onPoint: (point) => _select(point: point),
          onBox: (box) => _select(box: box),
        ),
      const SizedBox(height: 8),
      if (_status != null)
        Text(
          _status!,
          style: const TextStyle(fontSize: 11, color: AppTheme.muted),
        ),
      if (_busy)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        ),
      Wrap(
        spacing: 6,
        children: MaskTool.values
            .map(
              (tool) => ChoiceChip(
                label: Text(switch (tool) {
                  MaskTool.point => 'Объект',
                  MaskTool.box => 'SAM хүрээ',
                  MaskTool.brush => 'Гар маск',
                  MaskTool.erase => 'Баллуур',
                }, style: const TextStyle(fontSize: 11)),
                selected: _tool == tool,
                onSelected:
                    _busy ||
                        (!_segmentation &&
                            (tool == MaskTool.point || tool == MaskTool.box))
                    ? null
                    : (_) => setState(() => _tool = tool),
              ),
            )
            .toList(),
      ),
      if (_tool == MaskTool.brush || _tool == MaskTool.erase)
        Row(
          children: [
            TextButton(
              onPressed: _busy ? null : _acceptManual,
              child: const Text('Маск батлах'),
            ),
            TextButton(
              onPressed: _busy ? null : _editor.undo,
              child: const Text('Буцаах'),
            ),
            TextButton(
              onPressed: _busy ? null : _editor.clear,
              child: const Text('Цэвэрлэх'),
            ),
          ],
        ),
      if (_draft.masks.isNotEmpty)
        Wrap(
          spacing: 6,
          children: _draft.masks
              .asMap()
              .entries
              .map(
                (entry) => InputChip(
                  label: Text(
                    '${entry.value.manual ? 'Гар маск' : 'Объект'} ${entry.key + 1}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  onPressed: _busy ? null : () => _correct(entry.key),
                  onDeleted: _busy
                      ? null
                      : () => setState(() => _draft.masks.removeAt(entry.key)),
                ),
              )
              .toList(),
        ),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _busy || _draft.masks.isEmpty ? null : _remove,
          icon: const Icon(Icons.auto_fix_normal_outlined, size: 18),
          label: Text('Сонгосон тавилгыг арилгах · ${_draft.masks.length}'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            side: const BorderSide(color: AppTheme.border),
          ),
        ),
      ),
      if (_draft.cleaned)
        TextButton.icon(
          onPressed: _busy ? null : _undoRemoval,
          icon: const Icon(Icons.undo),
          label: const Text('Арилгалтыг буцаах'),
        ),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Divider(color: AppTheme.border),
      ),
      const Text(
        '2. Хүссэнээ тайлбарлаарай',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _prompt,
        minLines: 4,
        maxLines: 8,
        maxLength: 2000,
        onChanged: (_) {
          _draft.preferences = _draft.preferences.copyWith(
            prompt: _prompt.text,
          );
        },
        decoration: const InputDecoration(
          counterText: '',
          suffixIcon: Tooltip(
            message: 'Дуу таних үйлчилгээ холбогдоогүй байна.',
            child: IconButton(
              onPressed: null,
              icon: Icon(Icons.mic_none, size: 19),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        children: ['Илүү цэлгэр', 'Модон тавилга', 'Ургамал нэмэх']
            .map(
              (text) => ActionChip(
                label: Text(text, style: const TextStyle(fontSize: 11)),
                onPressed: () {
                  if (!_prompt.text.contains(text)) {
                    _prompt.text = '${_prompt.text} $text.';
                  }
                },
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 16),
      Text(
        _draft.preferences.summary,
        style: const TextStyle(fontSize: 11, color: AppTheme.muted),
      ),
      const SizedBox(height: 10),
      const Text(
        'Зураг AI серверт боловсруулагдана. Бүтэц төгс хэвээр үлдэх баталгаа биш. Төсөв нь төлөвлөлтийн дүн.',
        style: TextStyle(fontSize: 10, color: AppTheme.muted),
      ),
      const SizedBox(height: 16),
      PrimaryButton(
        label: 'Шинэ тохижуулалт үүсгэх',
        onPressed: _busy ? null : _generate,
      ),
      if (!_api.configured)
        TextButton(
          onPressed: _busy
              ? null
              : () {
                  setState(() => _busy = true);
                  _initialize();
                },
          child: const Text('Холболтыг дахин шалгах'),
        ),
      const SizedBox(height: 12),
      PrimaryButton(
        label: 'Тавилгыг гараар байрлуулах',
        secondary: true,
        onPressed: _busy
            ? null
            : () async {
                setState(() => _busy = true);
                try {
                  final preview = await ProjectStore.storeImage(
                    _draft.workingImage.bytes,
                  );
                  final id = 'local-${DateTime.now().microsecondsSinceEpoch}';
                  await ProjectStore.instance.put(
                    SavedDesignProject(
                      id: id,
                      name: 'Миний өрөө',
                      jobId: '',
                      sourceImageId: _draft.sourceImageId ?? '',
                      outputImageId: _draft.workingImageId ?? '',
                      preferences: _draft.preferences,
                      created: DateTime.now().millisecondsSinceEpoch / 1000,
                      roomId: _draft.roomId,
                      backgroundImageId: _draft.workingImageId,
                      originalPath: _draft.sourceImage.path,
                      emptyPath: _draft.workingImage.path,
                      previewPath: preview,
                    ),
                  );
                  if (context.mounted) {
                    await Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlacementEditorScreen(projectId: id),
                      ),
                    );
                  }
                } catch (error) {
                  _show(error);
                } finally {
                  if (mounted) setState(() => _busy = false);
                }
              },
      ),
    ],
  );
}
