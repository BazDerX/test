import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SanaaBottomNavigation extends StatelessWidget {
  const SanaaBottomNavigation({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  final int selected;
  final ValueChanged<int> onSelected;
  static const labels = [
    'Нүүр',
    'Тавилга',
    'Тохижуулах',
    'Миний төсөл',
    'Профайл',
  ];
  static const icons = [
    Icons.home_outlined,
    Icons.chair_outlined,
    Icons.crop_free,
    Icons.folder_outlined,
    Icons.person_outline,
  ];
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    child: SafeArea(
      top: false,
      child: Row(
        children: List.generate(
          5,
          (i) => Expanded(
            child: InkWell(
              onTap: () => onSelected(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icons[i],
                      size: 23,
                      color: i == selected ? AppTheme.green : AppTheme.muted,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      labels[i],
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 9,
                        color: i == selected ? AppTheme.green : AppTheme.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 16,
                      height: 3,
                      decoration: BoxDecoration(
                        color: i == selected
                            ? AppTheme.green
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
