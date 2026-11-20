import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.onSubmitted,
    this.autofillHints,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
  });
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 13)),
      const SizedBox(height: 7),
      TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        onFieldSubmitted: onSubmitted,
        autofillHints: autofillHints,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autocorrect: false,
        enableSuggestions: !obscureText,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(hintText: hint, suffixIcon: suffixIcon),
      ),
    ],
  );
}
