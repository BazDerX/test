import 'package:flutter/material.dart';

import '../models/order_request.dart';
import '../models/furniture.dart';
import '../models/design_preferences.dart';

class CartProductRow extends StatelessWidget {
  const CartProductRow({
    super.key,
    required this.item,
    required this.product,
    this.onIncrease,
    this.onDecrease,
    this.onRemove,
    this.onTap,
  });
  final CartItem item;
  final Furniture? product;
  final VoidCallback? onIncrease, onDecrease, onRemove, onTap;
  String cm(double v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product != null)
          GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                product!.imagePaths.first,
                width: 72,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product?.name ?? 'Каталогоос хасагдсан бараа',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (product != null)
                Text(
                  '${product!.color} · ${cm(product!.widthCm)} × ${cm(product!.depthCm)} × ${cm(product!.heightCm)} см',
                  style: const TextStyle(fontSize: 11),
                ),
              Text('${formatMoney(item.unitPrice)} ₮'),
              if (onRemove != null)
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Тоо хасах',
                      onPressed: item.quantity > 1 ? onDecrease : null,
                      icon: const Icon(Icons.remove, size: 16),
                    ),
                    Text('${item.quantity}'),
                    IconButton(
                      tooltip: 'Тоо нэмэх',
                      onPressed: onIncrease,
                      icon: const Icon(Icons.add, size: 16),
                    ),
                    IconButton(
                      tooltip: 'Сагснаас хасах',
                      onPressed: onRemove,
                      icon: const Icon(Icons.delete_outline, size: 18),
                    ),
                  ],
                )
              else
                Text('${item.quantity} ширхэг · ${formatMoney(item.total)} ₮'),
            ],
          ),
        ),
      ],
    ),
  );
}
