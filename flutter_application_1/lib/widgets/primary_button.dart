import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondary = false,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool secondary;
  final bool loading;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: secondary ? Colors.white : AppTheme.green,
        foregroundColor: secondary ? AppTheme.green : Colors.white,
        disabledBackgroundColor: AppTheme.green,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: secondary
              ? const BorderSide(color: AppTheme.border)
              : BorderSide.none,
        ),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
                semanticsLabel: 'Түр хүлээнэ үү',
              ),
            )
          : Text(label),
    ),
  );
}
