import 'package:flutter/material.dart';

import '../services/furniture_store.dart';
import '../screens/shopping_cart_screen.dart';

class FurnitureCartButton extends StatelessWidget {
  const FurnitureCartButton({super.key, required this.store});
  final FurnitureStore store;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => TextButton.icon(
      icon: const Icon(Icons.shopping_bag_outlined, size: 18),
      label: Text('Сагс · ${store.cartCount}'),
      onPressed: () => Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => ShoppingCartScreen(store: store)),
      ),
    ),
  );
}
