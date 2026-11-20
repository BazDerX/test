import 'package:flutter/material.dart';

import '../models/design_furniture.dart';
import '../models/design_preferences.dart';
import '../widgets/design_screen_layout.dart';

class DesignFurnitureScreen extends StatelessWidget {
  const DesignFurnitureScreen({super.key, required this.items});
  final List<DesignFurniture>? items;
  @override
  Widget build(BuildContext context) => DesignScreenLayout(
    title: 'Тохижуулалтын тавилгууд',
    children: [
      if (items == null)
        const Text(
          'Энэ тохижуулалтын тавилгын жагсаалт серверээс ирээгүй байна. Үнэ болон тоо хэмжээ одоогоор тодорхойгүй.',
        )
      else if (items!.isEmpty)
        const Text('Энэ тохижуулалтад бүртгэлтэй тавилга алга.')
      else
        ...items!.map(
          (item) => Card(
            color: Colors.white,
            child: ListTile(
              leading: const Icon(Icons.chair_outlined),
              title: Text(item.name),
              subtitle: Text('${item.quantity} ширхэг'),
              trailing: Text(
                item.unitPrice == null
                    ? 'Үнэ тодорхойгүй'
                    : '${formatMoney(item.unitPrice! * item.quantity)} ₮',
              ),
            ),
          ),
        ),
    ],
  );
}
