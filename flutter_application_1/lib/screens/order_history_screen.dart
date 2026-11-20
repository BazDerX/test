import 'package:flutter/material.dart';

import '../services/order_request_service.dart';
import '../models/furniture_company.dart';
import '../models/design_preferences.dart';
import '../widgets/design_screen_layout.dart';
import '../widgets/profile_navigation.dart';
import 'order_status_screen.dart';

String orderCompanyName(String id) =>
    furnitureCompanies.where((c) => c.id == id).firstOrNull?.name ?? 'Компани';
String orderDate(DateTime time) => time.toLocal().toString().substring(0, 16);

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});
  @override
  State<OrderHistoryScreen> createState() => _HistoryState();
}

class _HistoryState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    OrderHistoryStore.instance.load();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: OrderHistoryStore.instance,
    builder: (context, _) {
      final state = OrderHistoryStore.instance;
      return DesignScreenLayout(
        title: 'Миний захиалгууд',
        bottomNavigationBar: const ProfileNavigation(),
        children: [
          if (state.loading) const LinearProgressIndicator(),
          if (state.error != null) ...[
            Text(state.error!),
            TextButton(
              onPressed: state.load,
              child: const Text('Дахин оролдох'),
            ),
          ],
          if (!state.loading && state.error == null && state.items.isEmpty)
            const Text('Захиалгын хүсэлт одоогоор алга.'),
          ...state.items.map(
            (r) => Card(
              color: Colors.white,
              child: ListTile(
                title: Text(r.orderId),
                subtitle: Text(
                  '${orderCompanyName(r.companyId)} · ${orderDate(r.createdAt)}\n${formatMoney(r.subtotal)} ₮ · ${r.statusLabel}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderStatusScreen(orderId: r.orderId),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
