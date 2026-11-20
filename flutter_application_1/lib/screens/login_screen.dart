import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

/// Inject a real authentication request when a backend is available.
typedef LoginRequest = Future<void> Function(
  String identifier,
  String password,
);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.loginRequest});
  final LoginRequest? loginRequest;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _hidden = true;
  bool _loading = false;
  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validateIdentifier(String? input) {
    final value = input?.trim() ?? '';
    if (value.isEmpty) return 'Имэйл эсвэл утасны дугаараа оруулна уу.';
    if (RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value) ||
        RegExp(r'^(\+976)?[0-9]{8}$')
            .hasMatch(value.replaceAll(RegExp(r'[\s-]'), ''))) {
      return null;
    }
    return 'Зөв имэйл эсвэл 8 оронтой утасны дугаар оруулна уу.';
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      if (widget.loginRequest == null) {
        await AuthService.instance.login(
          _identifier.text.trim(),
          _password.text,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Туршилтын горим: бодит нэвтрэлт хийгдээгүй.'),
          ),
        );
      } else {
        await widget.loginRequest!(_identifier.text.trim(), _password.text);
      }
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нэвтрэхэд алдаа гарлаа. Дахин оролдоно уу.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Нэвтрэх'),
      leading: IconButton(
        tooltip: 'Буцах',
        icon: const Icon(Icons.arrow_back, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    body: SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 342 / 191,
                        child: Image.asset(
                          'assets/images/living_room.png',
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, 0.15),
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Тавтай морил.',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Таны хадгалсан санаанууд хүлээж байна.',
                      style: TextStyle(fontSize: 14, color: AppTheme.muted),
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'Имэйл эсвэл утасны дугаар',
                      controller: _identifier,
                      hint: 'nomin@example.mn',
                      validator: _validateIdentifier,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.username],
                    ),
                    const SizedBox(height: 18),
                    CustomTextField(
                      label: 'Нууц үг',
                      controller: _password,
                      hint: '••••••••••',
                      obscureText: _hidden,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Нууц үгээ оруулна уу.'
                          : null,
                      onSubmitted: (_) => _submit(),
                      suffixIcon: IconButton(
                        tooltip: _hidden ? 'Нууц үг харуулах' : 'Нууц үг нуух',
                        onPressed: () => setState(() => _hidden = !_hidden),
                        icon: Icon(
                          _hidden
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 19,
                          color: AppTheme.muted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        onPressed: () =>
                            Navigator.pushNamed(context, '/forgot-password'),
                        child: const Text('Нууц үгээ мартсан уу?'),
                      ),
                    ),
                    const SizedBox(height: 4),
                    PrimaryButton(
                      label: 'Нэвтрэх',
                      loading: _loading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(
                          context,
                          '/register',
                        ),
                        child: const Text('Шинэ хэрэглэгч үү? Бүртгүүлэх'),
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
