import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/furniture_card.dart';
import '../widgets/placeholder_page.dart';
import '../services/design_draft_store.dart';
import 'style_selection_screen.dart';
import 'projects_screen.dart';
import '../services/furniture_store.dart';
import '../models/design_preferences.dart';
import '../widgets/furniture_cart_button.dart';
import 'furniture_listing_screen.dart';
import 'furniture_details_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialTab = 0});
  final int initialTab;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selected = widget.initialTab;
  final _furniture = FurnitureStore.instance;
  Future<void> _resumeDesign() async {
    final draft = await DesignDraftStore.load();
    if (!mounted) return;
    if (draft == null) {
      Navigator.pushNamed(context, '/room-design');
    } else {
      Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => StyleSelectionScreen(draft: draft)),
      );
    }
  }

  void _detail(String title, String description) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => PlaceholderPage(title: title, description: description),
    ),
  );
  Widget _section(String title, String action, VoidCallback onTap) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      TextButton(
        onPressed: onTap,
        child: Text(action, style: const TextStyle(fontSize: 12)),
      ),
    ],
  );
  Widget _photo(String asset, double ratio) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: AspectRatio(
      aspectRatio: ratio,
      child: Image.asset('assets/images/$asset.png', fit: BoxFit.cover),
    ),
  );
  Widget _products() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: List.generate(
      2,
      (i) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(left: i == 1 ? 7 : 0, right: i == 0 ? 7 : 0),
          child: FurnitureCard(
            image: _furniture.products[i].imagePaths.first,
            name: _furniture.products[i].name,
            price: '${formatMoney(_furniture.products[i].price)} ₮',
            company: _furniture.products[i].company,
            has3DModel: _furniture.products[i].modelAvailable,
            favorite: _furniture.isFavorite(_furniture.products[i].id),
            onFavorite: () =>
                _furniture.toggleFavorite(_furniture.products[i].id),
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    FurnitureDetailsScreen(product: _furniture.products[i]),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  Widget _project() => InkWell(
    onTap: () => _detail(
      'Миний зочны өрөө',
      'Скандинав · 2 тавилга · Хадгалсан\nТөслийн засварлагч удахгүй нэмэгдэнэ.',
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _photo('home_living_room', 342 / 210),
        const SizedBox(height: 8),
        const Row(
          children: [
            Expanded(
              child: Text(
                'Миний зочны өрөө',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              'Өнөөдөр · 10:24',
              style: TextStyle(fontSize: 11, color: AppTheme.muted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Скандинав · 2 тавилга · Хадгалсан',
          style: TextStyle(fontSize: 12, color: AppTheme.green),
        ),
      ],
    ),
  );
  Widget _home() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'SANAA',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
          ),
          FurnitureCartButton(store: _furniture),
        ],
      ),
      const SizedBox(height: 18),
      Text(
        'Сайн уу, ${AuthService.instance.displayName} 👋',
        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 6),
      const Text(
        'Өнөөдөр гэртээ шинэ өнгө нэмье.',
        style: TextStyle(color: AppTheme.muted),
      ),
      const SizedBox(height: 20),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFEEEAE2),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Таны өрөөний шинэ боломж.',
              style: TextStyle(
                fontSize: 23,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Камераар скан хийх эсвэл өрөөний зургаа оруулаарай.',
              style: TextStyle(fontSize: 13, color: AppTheme.muted),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/room-design'),
                icon: const Icon(Icons.crop_free, size: 18),
                label: const Text('Өрөөгөө тохижуулах'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _section(
        'Үргэлжлүүлэх',
        'Бүх төсөл',
        () => setState(() => _selected = 3),
      ),
      const SizedBox(height: 8),
      _project(),
      const SizedBox(height: 12),
      _section(
        'Танд зориулсан санаа',
        'Бүгд',
        () => _detail(
          'Танд зориулсан санаа',
          'Санааны цуглуулга удахгүй нэмэгдэнэ.',
        ),
      ),
      const SizedBox(height: 8),
      InkWell(
        onTap: () => _detail(
          'Амрах орон зайн дулаан мэдрэмж',
          'Дулаан өнгө, байгалийн материал — өдөр тутмын тайван орон зай.',
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _photo('bedroom', 342 / 191),
            const SizedBox(height: 18),
            const Text(
              'Амрах орон зайн дулаан мэдрэмж',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            const Text(
              'Дулаан өнгө, байгалийн материал — өдөр тутмын тайван орон зай.',
              style: TextStyle(fontSize: 13, color: AppTheme.muted),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _section(
        'Онцлох тавилга',
        'Дэлгэрэнгүй',
        () => setState(() => _selected = 1),
      ),
      const SizedBox(height: 8),
      _products(),
    ],
  );
  Widget _destination() {
    if (_selected == 0) return _home();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          SanaaBottomNavigation.labels[_selected],
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),
        if (_selected == 1) _products(),
        if (_selected == 2) ...[
          const Text('Өрөөний скан, AI болон AR боломжууд удахгүй нэмэгдэнэ.'),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pushNamed(context, '/room-design'),
            child: const Text('Өрөөгөө тохижуулах'),
          ),
        ],
        if (_selected == 3) ...[
          FilledButton(
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const ProjectsScreen()),
            ),
            child: const Text('Хадгалсан AI төслүүд'),
          ),
          TextButton(
            onPressed: _resumeDesign,
            child: const Text('Тохижуулалтын ноорог үргэлжлүүлэх'),
          ),
          const SizedBox(height: 16),
          _project(),
        ],
        if (_selected == 4) ...[
          Text(
            AuthService.instance.displayName,
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(height: 12),
          const Text('Туршилтын горим · мэдээлэл зөвхөн түр хадгалагдана.'),
          const SizedBox(height: 16),
          Text('Хадгалсан тавилга: ${_furniture.favoriteCount}'),
          TextButton(
            onPressed: () =>
                Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false),
            child: const Text('Гарах'),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _furniture,
    builder: (context, _) => Scaffold(
      body: _selected == 4
          ? const ProfileScreen(embedded: true)
          : _selected == 3
          ? const ProjectsScreen(embedded: true)
          : _selected == 1
          ? FurnitureListingScreen(store: _furniture, embedded: true)
          : SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: SingleChildScrollView(
                    key: ValueKey(_selected),
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                    child: _destination(),
                  ),
                ),
              ),
            ),
      bottomNavigationBar: SanaaBottomNavigation(
        selected: _selected,
        onSelected: (i) => setState(() => _selected = i),
      ),
    ),
  );
}
