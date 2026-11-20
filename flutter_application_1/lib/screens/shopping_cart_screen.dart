import 'package:flutter/material.dart';

import '../services/furniture_store.dart';
import '../models/design_preferences.dart';
import '../widgets/design_screen_layout.dart';
import '../widgets/furniture_navigation.dart';
import '../widgets/cart_product_row.dart';
import '../widgets/primary_button.dart';
import 'furniture_listing_screen.dart';
import 'furniture_details_screen.dart';
import 'order_request_screen.dart';

class ShoppingCartScreen extends StatelessWidget {
  const ShoppingCartScreen({super.key, this.store});
  final FurnitureStore? store;
  @override
  Widget build(BuildContext context) {
    final state = store ?? FurnitureStore.instance;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final companies = state.cartItems.map((i) => i.companyId).toSet();
        return DesignScreenLayout(
          title: 'Миний сагс',
          bottomNavigationBar: const FurnitureNavigation(),
          children: [
            Text('${state.cartCount} бараа'),
            const SizedBox(height: 20),
            const Text(
              'Шинэ өрөөний эхний алхам.',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            if (state.persistenceError != null) Text(state.persistenceError!),
            if (companies.isEmpty) ...[
              const Text('Сагс хоосон байна.'),
              PrimaryButton(
                label: 'Тавилга үзэх',
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FurnitureListingScreen(store: state),
                  ),
                ),
              ),
            ],
            ...companies.map((id) {
              final items = state.cartItems
                  .where((i) => i.companyId == id)
                  .toList();
              final company =
                  state.products
                      .where((p) => p.id == items.first.furnitureId)
                      .firstOrNull
                      ?.company ??
                  'Компани';
              final subtotal = items.fold<int>(0, (n, i) => n + i.total);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.storefront_outlined),
                    title: Text(company),
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      children: items.map((i) {
                        final p = state.products
                            .where((p) => p.id == i.furnitureId)
                            .firstOrNull;
                        return CartProductRow(
                          item: i,
                          product: p,
                          onIncrease: p == null
                              ? null
                              : () => state.addToCart(i.furnitureId),
                          onDecrease: () => state.removeFromCart(i.furnitureId),
                          onRemove: () => state.deleteCartItem(i.furnitureId),
                          onTap: p == null
                              ? null
                              : () => Navigator.push<void>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FurnitureDetailsScreen(
                                      product: p,
                                      store: state,
                                    ),
                                  ),
                                ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Барааны дүн: ${formatMoney(subtotal)} ₮'),
                  const SizedBox(height: 8),
                  const Text('Хүргэлт · Компаниас баталгаажуулна'),
                  const Divider(),
                  Text(
                    'Нийт дүн: ${formatMoney(subtotal)} ₮',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    label: companies.length > 1
                        ? '$company · Хүсэлт гаргах'
                        : 'Захиалгын хүсэлт гаргах',
                    onPressed:
                        items.any(
                          (i) =>
                              !state.products.any((p) => p.id == i.furnitureId),
                        )
                        ? null
                        : () => Navigator.push<void>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderRequestScreen(
                                companyId: id,
                                store: state,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            }),
            if (companies.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EFE7),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  'Сагсны нийт: ${formatMoney(state.cartTotal)} ₮\nЭнэ нь худалдан авалтын хүсэлт юм. Онлайн төлбөр төлөхгүй. Компани үнэ, үлдэгдэл, хүргэлтийг баталгаажуулна. Одоогоор зөвхөн төхөөрөмжид түр хадгалагдана.',
                ),
              ),
          ],
        );
      },
    );
  }
}
