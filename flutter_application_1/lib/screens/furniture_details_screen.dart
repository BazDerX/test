import 'package:flutter/material.dart';

import '../models/furniture.dart';
import '../models/design_preferences.dart';
import '../services/furniture_store.dart';
import '../services/furniture_preview_service.dart';
import '../theme/app_theme.dart';
import '../widgets/furniture_cart_button.dart';
import '../widgets/furniture_navigation.dart';
import '../widgets/primary_button.dart';
import 'furniture_companies_screen.dart';
import '../models/furniture_company.dart';

class FurnitureDetailsScreen extends StatefulWidget {
  const FurnitureDetailsScreen({
    super.key,
    required this.product,
    this.store,
    this.previewService = const UnavailableFurniturePreview(),
  });
  final Furniture product;
  final FurnitureStore? store;
  final FurniturePreviewService previewService;
  @override
  State<FurnitureDetailsScreen> createState() => _FurnitureDetailsScreenState();
}

class _FurnitureDetailsScreenState extends State<FurnitureDetailsScreen> {
  FurnitureStore get _store => widget.store ?? FurnitureStore.instance;
  int _page = 0;
  Widget _spec(String title, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 12, color: AppTheme.muted),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    ),
  );
  String _cm(double value) =>
      value == value.roundToDouble() ? '${value.toInt()}' : '$value';
  @override
  Widget build(BuildContext context) {
    final item = widget.product;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Тавилгын дэлгэрэнгүй',
          style: TextStyle(fontSize: 16),
        ),
        actions: [FurnitureCartButton(store: _store)],
      ),
      bottomNavigationBar: const FurnitureNavigation(),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 1.1,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          PageView.builder(
                            itemCount: item.imagePaths.length,
                            onPageChanged: (page) =>
                                setState(() => _page = page),
                            itemBuilder: (_, index) => Image.asset(
                              item.imagePaths[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: ListenableBuilder(
                              listenable: _store,
                              builder: (context, _) => IconButton.filled(
                                tooltip: _store.isFavorite(item.id)
                                    ? 'Хадгалснаас хасах'
                                    : 'Хадгалах',
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.green,
                                ),
                                onPressed: () => _store.toggleFavorite(item.id),
                                icon: Icon(
                                  _store.isFavorite(item.id)
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 14,
                            left: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_page + 1} / ${item.imagePaths.length} зураг',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.muted,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Chip(
                        label: Text(
                          item.modelAvailable ? '3D / AR' : '3D загваргүй',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                        backgroundColor: AppTheme.green,
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${formatMoney(item.price)} ₮',
                    style: const TextStyle(
                      fontSize: 25,
                      color: AppTheme.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FurnitureCompaniesScreen(
                          companyId: furnitureCompanies
                              .where((c) => c.name == item.company)
                              .firstOrNull
                              ?.id,
                          store: _store,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.storefront_outlined, size: 18),
                    label: Text('${item.company} · Компани үзэх →'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.description,
                    style: const TextStyle(fontSize: 13, color: AppTheme.muted),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        _spec(
                          'Хэмжээ',
                          '${_cm(item.widthCm)} × ${_cm(item.depthCm)} × ${_cm(item.heightCm)} см',
                        ),
                        _spec('Материал', item.material),
                        _spec('Өнгө', item.color),
                        _spec(
                          'Баталгаат хугацаа',
                          '${item.warrantyMonths} сар',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    label: '3D загварыг эргүүлж үзэх',
                    secondary: true,
                    onPressed: () =>
                        widget.previewService.showModel(context, item),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final ar = PrimaryButton(
                        label: 'AR-аар турших',
                        secondary: true,
                        onPressed: () =>
                            widget.previewService.placeInRoom(context, item),
                      );
                      final cart = PrimaryButton(
                        label: 'Сагсанд нэмэх',
                        onPressed: () {
                          _store.addToCart(item.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item.name} сагсанд нэмэгдлээ.'),
                            ),
                          );
                        },
                      );
                      if (constraints.maxWidth < 340 ||
                          MediaQuery.textScalerOf(context).scale(14) > 18) {
                        return Column(
                          children: [ar, const SizedBox(height: 12), cart],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: ar),
                          const SizedBox(width: 10),
                          Expanded(child: cart),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Жишиг бүтээгдэхүүн · Үнэ болон техникийн мэдээллийг худалдаалагчтай баталгаажуулна уу.',
                    style: TextStyle(fontSize: 11, color: AppTheme.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
