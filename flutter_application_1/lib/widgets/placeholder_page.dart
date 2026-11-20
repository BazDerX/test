import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'primary_button.dart';

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    super.key,
    required this.title,
    required this.description,
  });
  final String title;
  final String description;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      leading: IconButton(
        tooltip: 'Буцах',
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, size: 20),
      ),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SANAA',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            Text(description, style: const TextStyle(color: AppTheme.muted)),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Буцах',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    ),
  );
}
