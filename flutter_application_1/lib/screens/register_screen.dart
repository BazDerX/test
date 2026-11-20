import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _hidden = true, _accepted = false, _loading = false, _termsError = false;
  @override
  void dispose() {
    _name.dispose();
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    final valid = _form.currentState!.validate();
    setState(() => _termsError = !_accepted);
    if (!valid || !_accepted) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await AuthService.instance.register(
        _name.text,
        _identifier.text,
        _password.text,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Туршилтын горим: бодит бүртгэл үүсээгүй.'),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Алдаа гарлаа. Дахин оролдоно уу.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Бүртгүүлэх'),
      leading: IconButton(
        tooltip: 'Буцах',
        icon: const Icon(Icons.arrow_back, size: 20),
        onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
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
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: AutofillGroup(
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Шинэ орон зай эндээс эхэлнэ.',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Санаагаа хадгалж, өөрийн гэрийг бүтээхэд бэлэн үү?',
                      style: TextStyle(color: AppTheme.muted),
                    ),
                    const SizedBox(height: 22),
                    CustomTextField(
                      label: 'Таны нэр',
                      controller: _name,
                      hint: 'Номин',
                      autofillHints: const [AutofillHints.name],
                      validator: (v) => (v?.trim().runes.length ?? 0) < 2
                          ? 'Нэрээ 2-оос доошгүй тэмдэгтээр оруулна уу.'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'Имэйл эсвэл утасны дугаар',
                      controller: _identifier,
                      hint: 'nomin@example.mn',
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.username],
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                    .hasMatch(value) ||
                                RegExp(r'^(\+976)?[0-9]{8}$').hasMatch(
                                  value.replaceAll(RegExp(r'[\s-]'), ''),
                                )
                            ? null
                            : 'Зөв имэйл эсвэл 8 оронтой утасны дугаар оруулна уу.';
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'Нууц үг',
                      controller: _password,
                      hint: '••••••••••',
                      obscureText: _hidden,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      validator: (v) {
                        final value = v ?? '';
                        return value.length >= 8 &&
                                RegExp(r'[A-ZА-ЯӨҮЁ]').hasMatch(value) &&
                                RegExp(r'[a-zа-яөүё]').hasMatch(value) &&
                                RegExp(r'[0-9]').hasMatch(value)
                            ? null
                            : '8-аас доошгүй тэмдэгт, том жижиг үсэг, тоо оруулна уу.';
                      },
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
                    const SizedBox(height: 20),
                    const Text(
                      '8-аас дээш тэмдэгт, том жижиг үсэг болон тоо ашиглаарай.',
                      style: TextStyle(fontSize: 11, color: AppTheme.muted),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 30,
                          child: Checkbox(
                            value: _accepted,
                            onChanged: _loading
                                ? null
                                : (v) => setState(() {
                                    _accepted = v!;
                                    _termsError = !v;
                                  }),
                            activeColor: AppTheme.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'Үйлчилгээний нөхцөл, нууцлалын бодлогыг уншиж зөвшөөрч байна.',
                              style: TextStyle(fontSize: 12, height: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_termsError)
                      const Text(
                        'Үйлчилгээний нөхцөлийг зөвшөөрнө үү.',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Бүртгэл үүсгэх',
                      loading: _loading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/login'),
                        child: const Text('Бүртгэлтэй юу? Нэвтрэх'),
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
