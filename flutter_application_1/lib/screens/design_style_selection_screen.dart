import 'package:flutter/material.dart';

import '../models/design_preferences.dart';
import '../models/room_design_project.dart';
import '../services/design_draft_store.dart';
import '../theme/app_theme.dart';
import '../widgets/design_screen_layout.dart';
import '../widgets/primary_button.dart';
import '../widgets/room_progress_indicator.dart';
import 'ai_interior_screen.dart';

class StyleSelectionScreen extends StatefulWidget {
  const StyleSelectionScreen({super.key, required this.draft});
  final RoomDesignProject draft;
  @override
  State<StyleSelectionScreen> createState() => _StyleSelectionScreenState();
}

class _StyleSelectionScreenState extends State<StyleSelectionScreen> {
  DesignPreferences get _prefs => widget.draft.preferences;
  bool _busy = false;
  void _update(DesignPreferences p) {
    setState(() => widget.draft.preferences = p);
  }

  Future<void> _save() async {
    try {
      await DesignDraftStore.save(widget.draft);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ноорог хадгалж чадсангүй.')),
        );
      }
    }
  }

  Future<void> _next() async {
    setState(() => _busy = true);
    await _save();
    if (!mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => AiInteriorScreen(draft: widget.draft)),
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => DesignScreenLayout(
    title: 'Таны хэв маяг',
    children: [
      const RoomProgressIndicator(step: 2),
      const SizedBox(height: 22),
      const Text(
        'Танд ямар орон зай таалагддаг вэ?',
        style: TextStyle(
          fontSize: 27,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      ),
      const SizedBox(height: 22),
      GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: .84,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: DesignPreferences.styles.entries.map((entry) {
          final selected = _prefs.style == entry.key;
          final asset = switch (entry.key) {
            'scandinavian' => 'home_living_room',
            'warm_minimal' => 'bedroom',
            'modern' => 'living_room',
            _ => 'room_input',
          };
          return InkWell(
            onTap: () {
              _update(_prefs.copyWith(style: entry.key));
              _save();
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFE8EFE7) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? AppTheme.green : AppTheme.border,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/$asset.png',
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (selected)
                        const Icon(
                          Icons.check,
                          size: 14,
                          color: AppTheme.green,
                        ),
                      if (selected) const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 24),
      const Text(
        'Өнгөний зохицол',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 16,
        runSpacing: 12,
        children: DesignPreferences.paletteColors.entries
            .map(
              (entry) => Semantics(
                selected: _prefs.palette == entry.key,
                button: true,
                label: DesignPreferences.palettes[entry.key],
                child: InkWell(
                  onTap: () {
                    _update(_prefs.copyWith(palette: entry.key));
                    _save();
                  },
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 46,
                    height: 46,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _prefs.palette == entry.key
                            ? AppTheme.green
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: entry.value,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 12),
      Text(
        'Сонгосон: ${DesignPreferences.palettes[_prefs.palette]} · Байгалийн дулаан өнгө',
        style: const TextStyle(fontSize: 12, color: AppTheme.muted),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Таны төсөв',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Text(
              '${formatMoney(_prefs.budget)} ₮',
              style: const TextStyle(
                fontSize: 28,
                color: AppTheme.green,
                fontWeight: FontWeight.w600,
              ),
            ),
            Slider(
              value: _prefs.budget.toDouble(),
              min: 500000,
              max: 5000000,
              divisions: 90,
              semanticFormatterCallback: (v) =>
                  '${formatMoney(v.round())} төгрөг',
              onChanged: (v) => _update(_prefs.copyWith(budget: v.round())),
              onChangeEnd: (_) => _save(),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '500,000 ₮',
                  style: TextStyle(fontSize: 10, color: AppTheme.muted),
                ),
                Text(
                  '5,000,000 ₮',
                  style: TextStyle(fontSize: 10, color: AppTheme.muted),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      PrimaryButton(
        label: 'AI тохижуулалт руу',
        loading: _busy,
        onPressed: _next,
      ),
    ],
  );
}
