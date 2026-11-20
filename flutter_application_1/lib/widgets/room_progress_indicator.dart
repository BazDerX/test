import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RoomProgressIndicator extends StatelessWidget {
  const RoomProgressIndicator({super.key, this.step = 1});
  final int step;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: List.generate(
          4,
          (i) => Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: i < 3 ? 5 : 0),
              decoration: BoxDecoration(
                color: i < step ? AppTheme.green : AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Text(
        'Алхам $step/4 · Өрөө → Хэв маяг → AI → Үр дүн',
        style: const TextStyle(fontSize: 11, color: AppTheme.muted),
      ),
    ],
  );
}
