import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/furniture_store.dart';
import '../widgets/design_screen_layout.dart';
import '../widgets/primary_button.dart';
import 'furniture_details_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditState();
}

class _EditState extends State<EditProfileScreen> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(
        text: AuthService.instance.displayName,
      ),
      email = TextEditingController(text: AuthService.instance.email),
      phone = TextEditingController(text: AuthService.instance.phone);
  bool busy = false;
  String? error;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DesignScreenLayout(
    title: 'Профайл засах',
    children: [
      Form(
        key: form,
        child: Column(
          children: [
            TextFormField(
              controller: name,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Овог, нэр'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Нэрээ оруулна уу.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Имэйл'),
              validator: (v) =>
                  (v ?? '').isEmpty ||
                      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v!)
                  ? null
                  : 'Имэйлээ зөв оруулна уу.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Утасны дугаар'),
              validator: (v) =>
                  (v ?? '').isEmpty ||
                      RegExp(r'^(?:\+976)?[5-9][0-9]{7}$')
                          .hasMatch(v!.replaceAll(' ', ''))
                  ? null
                  : 'Утасны дугаараа зөв оруулна уу.',
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      if (error != null) Text(error!),
      PrimaryButton(
        label: 'Хадгалах',
        loading: busy,
        onPressed: () async {
          if (!form.currentState!.validate() || busy) return;
          setState(() => busy = true);
          try {
            await AuthService.instance.updateProfile(
              name.text.trim(),
              email.text.trim(),
              phone.text.trim(),
            );
            if (context.mounted) Navigator.pop(context);
          } catch (_) {
            if (mounted) setState(() => error = 'Хадгалж чадсангүй.');
          } finally {
            if (mounted) setState(() => busy = false);
          }
        },
      ),
    ],
  );
}

class FavoriteFurnitureScreen extends StatelessWidget {
  const FavoriteFurnitureScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: FurnitureStore.instance,
    builder: (context, _) {
      final store = FurnitureStore.instance;
      final items = store.products.where((p) => store.isFavorite(p.id));
      return DesignScreenLayout(
        title: 'Таалагдсан тавилга',
        children: [
          if (items.isEmpty) const Text('Таалагдсан тавилга алга.'),
          ...items.map(
            (p) => ListTile(
              leading: Image.asset(
                p.imagePaths.first,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
              title: Text(p.name),
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => FurnitureDetailsScreen(product: p),
                ),
              ),
              trailing: IconButton(
                tooltip: 'Таалагдсанаас хасах',
                icon: const Icon(Icons.favorite),
                onPressed: () => store.toggleFavorite(p.id),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});
  @override
  State<ProfileSettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends State<ProfileSettingsScreen> {
  bool tips = true;
  String? error;
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance()
        .then((p) {
          if (mounted) {
            setState(() => tips = p.getBool('sanaa.help.tips') ?? true);
          }
        })
        .catchError((Object e) {
          if (mounted) setState(() => error = 'Тохиргоог уншиж чадсангүй.');
        });
  }

  @override
  Widget build(BuildContext context) => DesignScreenLayout(
    title: 'Тохиргоо, нууцлал',
    children: [
      if (error != null) Text(error!),
      const Text(
        'Профайл, сагс, хүсэлтийн ноорог энэ төхөөрөмжид хадгалагдана. Өрөөний зураг AI серверт боловсруулах үед дамжуулагдана. Нийтийн хуваалцах холбоос үүсгэхгүй.',
      ),
      SwitchListTile(
        title: const Text('Өрөө засах зөвлөмжийг харуулах'),
        value: tips,
        onChanged: (v) async {
          try {
            if (!await (await SharedPreferences.getInstance()).setBool(
              'sanaa.help.tips',
              v,
            )) {
              throw StateError('storage');
            }
            if (mounted) setState(() => tips = v);
          } catch (_) {
            if (mounted) setState(() => error = 'Хадгалж чадсангүй.');
          }
        },
      ),
    ],
  );
}
