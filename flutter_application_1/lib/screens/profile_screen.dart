import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/project_store.dart';
import '../services/order_request_service.dart';
import '../services/furniture_store.dart';
import '../models/design_preferences.dart';
import '../widgets/design_screen_layout.dart';
import '../widgets/profile_navigation.dart';
import '../widgets/primary_button.dart';
import '../widgets/placeholder_page.dart';
import 'order_history_screen.dart';
import 'order_status_screen.dart';
import 'furniture_companies_screen.dart';
import 'profile_tools_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.embedded = false});
  final bool embedded;
  @override
  State<ProfileScreen> createState() => _ProfileState();
}

class _ProfileState extends State<ProfileScreen> {
  String? error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await Future.wait([
        AuthService.instance.loadProfile(),
        ProjectStore.instance.load(),
        OrderHistoryStore.instance.load(),
      ]);
    } catch (_) {
      if (mounted) setState(() => error = 'Мэдээллийг уншиж чадсангүй.');
    }
  }

  void open(Widget screen) =>
      Navigator.push<void>(context, MaterialPageRoute(builder: (_) => screen));
  Widget menu(IconData icon, String title, VoidCallback action) => Column(
    children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: const Color(0xFF315C47)),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: action,
      ),
      const Divider(height: 1),
    ],
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      AuthService.instance,
      ProjectStore.instance,
      OrderHistoryStore.instance,
      FurnitureStore.instance,
    ]),
    builder: (context, _) {
      final user = AuthService.instance;
      final orders = OrderHistoryStore.instance;
      final recent = orders.items.firstOrNull;
      return DesignScreenLayout(
        title: 'Профайл',
        bottomNavigationBar: widget.embedded ? null : const ProfileNavigation(),
        children: [
          if (error != null) Text(error!),
          if (orders.error != null) Text(orders.error!),
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: const Color(0xFFEEE9DE),
                child: Text(
                  user.displayName.isEmpty
                      ? '?'
                      : user.displayName.characters.first,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(user.email.isEmpty ? 'Имэйл бүртгээгүй' : user.email),
                    Text(user.phone.isEmpty ? 'Утас бүртгээгүй' : user.phone),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Профайл засах',
                onPressed: () => open(const EditProfileScreen()),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Дотоод профайл · Нэвтрэлт туршилтын горимтой.'),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EFE7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                Text(
                  '${ProjectStore.instance.items.where((p) => p.saved).length} хадгалсан төсөл',
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  '${orders.items.length} захиалгын хүсэлт',
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (recent == null)
            const Text('Захиалгын хүсэлт одоогоор алга.')
          else
            Card(
              color: Colors.white,
              child: ListTile(
                title: Text(recent.orderId),
                subtitle: Text(
                  '${recent.statusLabel}\n${orderCompanyName(recent.companyId)} · ${formatMoney(recent.subtotal)} ₮\nХүсэлтийн төлөв харах →',
                ),
                onTap: () => open(OrderStatusScreen(orderId: recent.orderId)),
              ),
            ),
          const SizedBox(height: 20),
          menu(
            Icons.assignment_outlined,
            'Миний захиалгууд',
            () => open(const OrderHistoryScreen()),
          ),
          menu(
            Icons.favorite_border,
            'Таалагдсан тавилга',
            () => open(const FavoriteFurnitureScreen()),
          ),
          Text('Хадгалсан тавилга: ${FurnitureStore.instance.favoriteCount}'),
          menu(
            Icons.storefront_outlined,
            'Тавилгын компаниуд',
            () => open(const FurnitureCompaniesScreen()),
          ),
          menu(
            Icons.notifications_none,
            'Мэдэгдэл',
            () => open(
              const PlaceholderPage(
                title: 'Мэдэгдэл',
                description: 'Мэдэгдэл одоогоор алга. Түлхэх мэдэгдлийн үйлчилгээ холбогдоогүй.',
              ),
            ),
          ),
          menu(
            Icons.settings_outlined,
            'Тохиргоо, нууцлал',
            () => open(const ProfileSettingsScreen()),
          ),
          menu(
            Icons.help_outline,
            'Тусламж, холбоо барих',
            () => open(
              const PlaceholderPage(
                title: 'Тусламж, холбоо барих',
                description: 'Өрөөний зураг оруулж тохижуулаад төслөө хадгална уу. Тавилгыг сагсанд нэмж хүсэлтээ төхөөрөмждөө түр хадгалж болно.\nТусламжийн утас, имэйл тохируулаагүй байна.',
              ),
            ),
          ),
          const SizedBox(height: 24),
          const PrimaryButton(label: 'Гарах', secondary: true, onPressed: null),
          const SizedBox(height: 8),
          const Text('Серверийн нэвтрэлт, гарах үйлчилгээ холбогдоогүй.'),
          const SizedBox(height: 24),
          const Center(child: Text('SANAA · Хувилбар 1.0')),
        ],
      );
    },
  );
}
