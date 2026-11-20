import 'dart:async';

import 'package:flutter/material.dart';

import '../models/ai_generation_job.dart';
import '../models/design_preferences.dart';
import '../models/room_design_project.dart';
import '../services/ai_api_service.dart';
import '../services/design_draft_store.dart';
import '../widgets/primary_button.dart';
import '../widgets/room_progress_indicator.dart';
import '../theme/app_theme.dart';
import 'ai_result_screen.dart';

class AiProcessingScreen extends StatefulWidget {
  const AiProcessingScreen({super.key, required this.draft, this.api});
  final RoomDesignProject draft;
  final AiApiService? api;
  @override
  State<AiProcessingScreen> createState() => _AiProcessingScreenState();
}

class _AiProcessingScreenState extends State<AiProcessingScreen> {
  AiApiService get _api => widget.api ?? AiApiService.instance;
  AiGenerationJob? _job;
  String? _error;
  bool _cancelled = false, _leaving = false;
  Timer? _delay;
  Completer<void>? _wait;
  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() => _error = null);
    try {
      // Resume an interrupted poll rather than submitting a duplicate job.
      var job = _job != null && !['failed', 'cancelled'].contains(_job!.status)
          ? await _api.job(_job!.id)
          : await _api.generate(widget.draft);
      _job = job;
      if (_cancelled || !mounted) {
        await _api.cancel(job.id);
        return;
      }
      if (!widget.draft.previousJobIds.contains(job.id)) {
        widget.draft.previousJobIds.add(job.id);
      }
      try {
        await DesignDraftStore.save(widget.draft);
      } catch (_) {
        /* The server job remains durable if local storage is full. */
      }
      while (mounted && !_cancelled) {
        setState(() => _job = job);
        if (job.status == 'completed') {
          if (job.outputImageId == null) {
            throw const AiApiException('Сервер үр дүнгийн зураг буцаасангүй.');
          }
          final bytes = await _api.imageBytes(job.outputImageId!);
          if (!mounted || _cancelled) return;
          _leaving = true;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute<void>(
              builder: (_) => AiResultScreen(
                draft: widget.draft,
                job: job,
                generatedBytes: bytes,
                api: _api,
              ),
            ),
          );
          return;
        }
        if (job.status == 'failed' || job.status == 'cancelled') {
          throw AiApiException(job.error ?? 'Ажил цуцлагдсан.');
        }
        _wait = Completer<void>();
        _delay = Timer(const Duration(seconds: 2), () {
          if (!_wait!.isCompleted) _wait!.complete();
        });
        await _wait!.future;
        if (_cancelled || !mounted) return;
        job = await _api.job(job.id);
      }
    } catch (error) {
      if (mounted && !_cancelled) {
        setState(
          () => _error = error is AiApiException
              ? error.message
              : 'AI ажиллуулалт амжилтгүй боллоо.',
        );
      }
    }
  }

  Future<void> _cancel() async {
    if (_cancelled) return;
    _cancelled = true;
    _delay?.cancel();
    if (_wait != null && !_wait!.isCompleted) _wait!.complete();
    if (_job != null && !_job!.terminal) {
      try {
        await _api.cancel(_job!.id);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Серверт цуцлалт хүрсэнгүй. Ажлын төлөвийг дараа шалгана уу.',
              ),
            ),
          );
        }
      }
    }
    if (mounted) {
      setState(() => _leaving = true);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    if (!_leaving && _job != null && !_job!.terminal) {
      unawaited(_api.cancel(_job!.id).catchError((Object _) {}));
    }
    _cancelled = true;
    _delay?.cancel();
    if (_wait != null && !_wait!.isCompleted) _wait!.complete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _leaving,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _cancel();
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Санааг тань бүтээж байна'),
        leading: IconButton(
          tooltip: 'Цуцлах',
          onPressed: _cancel,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const RoomProgressIndicator(step: 3),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 342 / 270,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(
                            widget.draft.sourceImage.bytes,
                            fit: BoxFit.cover,
                          ),
                          ColoredBox(
                            color: Colors.white.withValues(alpha: .58),
                          ),
                          const Center(
                            child: CircleAvatar(
                              radius: 31,
                              backgroundColor: AppTheme.green,
                              child: Icon(
                                Icons.auto_awesome_outlined,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Таны өрөөнд тохирох шийдлийг олж байна.',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text(
                          DesignPreferences.styles[widget
                                  .draft
                                  .preferences
                                  .style] ??
                              widget.draft.preferences.style,
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: AppTheme.green,
                        side: BorderSide.none,
                      ),
                      Chip(
                        label: Text(
                          '${formatMoney(widget.draft.preferences.budget)} ₮',
                        ),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppTheme.border),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _stage(
                    'Өрөөний бүтцийг таньсан',
                    _job?.parameters['structure_recognized'] == true,
                  ),
                  _stage(
                    'Хуучин тавилгыг арилгасан',
                    widget.draft.cleaned ||
                        _job?.parameters['furniture_removed'] == true,
                  ),
                  _stage(
                    'Тавилга, өнгийг зохицуулж байна',
                    false,
                    active: _error == null && _job?.status == 'running',
                  ),
                  const SizedBox(height: 16),
                  if (_error == null)
                    TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0,
                        end: _job?.progress?.clamp(0.0, 1.0) ?? 0,
                      ),
                      duration: const Duration(milliseconds: 650),
                      builder: (context, value, child) =>
                          LinearProgressIndicator(
                            value: _job?.progress == null ? null : value,
                            minHeight: 5,
                            borderRadius: BorderRadius.circular(4),
                            backgroundColor: AppTheme.border,
                          ),
                    ),
                  const SizedBox(height: 18),
                  Text(
                    _error ?? _job?.message ?? 'Серверт хүсэлт илгээж байна…',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _error == null
                          ? AppTheme.muted
                          : Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Таны зураг болон сонголтууд хадгалагдсан. Хугацаа нь серверийн ачааллаас хамаарна.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.muted, fontSize: 12),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    PrimaryButton(label: 'Дахин оролдох', onPressed: _run),
                  ],
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: _error == null ? 'Үүсгэхийг зогсоох' : 'Буцах',
                    secondary: true,
                    onPressed: _cancel,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _stage(String label, bool complete, {bool active = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        if (active)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          )
        else
          Icon(
            complete
                ? Icons.check_circle_outline
                : Icons.radio_button_unchecked,
            size: 20,
            color: complete ? AppTheme.green : AppTheme.muted,
          ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: active ? AppTheme.green : AppTheme.muted,
            ),
          ),
        ),
      ],
    ),
  );
}
