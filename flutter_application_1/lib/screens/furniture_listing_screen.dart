import 'package:flutter/material.dart';

import '../models/furniture.dart';
import '../models/design_preferences.dart';
import '../services/furniture_store.dart';
import '../theme/app_theme.dart';
import '../widgets/furniture_card.dart';
import '../widgets/furniture_cart_button.dart';
import '../widgets/furniture_navigation.dart';
import 'furniture_filter_screen.dart';
import 'furniture_details_screen.dart';
import 'furniture_companies_screen.dart';

class FurnitureListingScreen extends StatefulWidget {
  const FurnitureListingScreen({super.key, this.store, this.embedded = false});
  final FurnitureStore? store;
  final bool embedded;
  @override
  State<FurnitureListingScreen> createState() => _FurnitureListingScreenState();
}

class _FurnitureListingScreenState extends State<FurnitureListingScreen> {
  FurnitureStore get _store => widget.store ?? FurnitureStore.instance;
  late final _search = TextEditingController(text: _store.query);
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListenableBuilder(
            listenable: _store,
            builder: (context, _) {
              final products = _store.visibleProducts;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Тавилга',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        FurnitureCartButton(store: _store),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Таны орон зайд яг тохирох тавилга.',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text('Тавилга хайх', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _search,
                      onChanged: _store.setQuery,
                      decoration: InputDecoration(
                        hintText: 'Буйдан, ширээ, сандал…',
                        suffixIcon: _store.query.isEmpty
                            ? const Icon(Icons.search, size: 20)
                            : IconButton(
                                tooltip: 'Хайлтыг цэвэрлэх',
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _search.clear();
                                  _store.setQuery('');
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [null, 'Буйдан', 'Ширээ', 'Сандал']
                          .map(
                            (category) => ChoiceChip(
                              label: Text(
                                category ?? 'Бүгд',
                                style: TextStyle(
                                  color: _store.filters.category == category
                                      ? Colors.white
                                      : AppTheme.ink,
                                ),
                              ),
                              selected: _store.filters.category == category,
                              showCheckmark: false,
                              selectedColor: AppTheme.green,
                              backgroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              onSelected: (_) => _store.applyFilters(
                                _store.filters.withCategory(category),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () async {
                            final filters =
                                await Navigator.push<FurnitureFilters>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        FurnitureFilterScreen(store: _store),
                                  ),
                                );
                            if (filters != null) _store.applyFilters(filters);
                          },
                          icon: const Icon(Icons.tune, size: 18),
                          label: Text(
                            'Шүүх${_store.filters.activeCount == 0 ? '' : ' · ${_store.filters.activeCount}'}',
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          flex: 3,
                          child: DropdownButton<FurnitureSort>(
                            value: _store.sort,
                            isExpanded: true,
                            underline: const SizedBox(),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.muted,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: FurnitureSort.recommended,
                                child: Text('Санал болгох'),
                              ),
                              DropdownMenuItem(
                                value: FurnitureSort.lowestPrice,
                                child: Text('Үнэ өсөхөөр'),
                              ),
                              DropdownMenuItem(
                                value: FurnitureSort.highestPrice,
                                child: Text('Үнэ буурахаар'),
                              ),
                            ],
                            onChanged: (sort) {
                              if (sort != null) _store.setSort(sort);
                            },
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${products.length} тавилга',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.muted,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (products.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.search_off,
                              size: 40,
                              color: AppTheme.muted,
                            ),
                            const Text('Тохирох тавилга олдсонгүй.'),
                            TextButton(
                              onPressed: () {
                                _search.clear();
                                _store.setQuery('');
                                _store.applyFilters(const FurnitureFilters());
                              },
                              child: const Text('Хайлт, шүүлтүүрийг цэвэрлэх'),
                            ),
                          ],
                        ),
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) => Wrap(
                          spacing: 14,
                          runSpacing: 22,
                          children: products
                              .map(
                                (item) => SizedBox(
                                  width: (constraints.maxWidth - 14) / 2,
                                  child: FurnitureCard(
                                    image: item.imagePaths.first,
                                    name: item.name,
                                    price: '${formatMoney(item.price)} ₮',
                                    company: item.company,
                                    has3DModel: item.modelAvailable,
                                    favorite: _store.isFavorite(item.id),
                                    onFavorite: () =>
                                        _store.toggleFavorite(item.id),
                                    onTap: () => Navigator.push<void>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FurnitureDetailsScreen(
                                          product: item,
                                          store: _store,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              FurnitureCompaniesScreen(store: _store),
                        ),
                      ),
                      child: const Text('Тавилгын компаниуд'),
                    ),
                    const Text(
                      'Жишиг каталог · 3D загварууд хараахан бэлэн болоогүй байна.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppTheme.muted),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
    return widget.embedded
        ? body
        : Scaffold(
            body: body,
            bottomNavigationBar: const FurnitureNavigation(),
          );
  }
}
