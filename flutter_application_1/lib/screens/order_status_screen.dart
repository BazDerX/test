import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/order_request_service.dart';
import '../services/furniture_store.dart';
import '../models/furniture_company.dart';
import '../models/design_preferences.dart';
import '../models/order_request.dart';
import '../widgets/design_screen_layout.dart';
import '../widgets/profile_navigation.dart';
import '../widgets/cart_product_row.dart';
import '../widgets/primary_button.dart';
import 'order_history_screen.dart';

class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen({
    super.key,
    required this.orderId,
    this.initialRequest,
  });
  final String orderId;
  final OrderRequest? initialRequest;
  @override
  State<OrderStatusScreen> createState() => _StatusState();
}

class _StatusState extends State<OrderStatusScreen> {
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
      final r = state.find(widget.orderId) ?? widget.initialRequest;
      if (r == null) {
        return DesignScreenLayout(
          title: 'Хүсэлтийн төлөв',
          children: [
            Text(
              state.loading
                  ? 'Уншиж байна…'
                  : state.error ?? 'Хүсэлт олдсонгүй.',
            ),
          ],
        );
      }
      final company = furnitureCompanies
          .where((c) => c.id == r.companyId)
          .firstOrNull;
      final phone = company?.phone;
      return DesignScreenLayout(
        title: 'Хүсэлтийн төлөв',
        bottomNavigationBar: const ProfileNavigation(),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EFE7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  r.effectiveStatus == 'draft'
                      ? Icons.save_outlined
                      : Icons.info_outline,
                  color: const Color(0xFF315C47),
                ),
                Text(
                  r.statusLabel,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text('№ ${r.orderId} · ${orderDate(r.createdAt)}'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            r.effectiveStatus == 'draft'
                ? '${orderCompanyName(r.companyId)} компанид илгээгдээгүй. Хүсэлт зөвхөн энэ төхөөрөмжид хадгалагдсан.'
                : '${orderCompanyName(r.companyId)} · Төлөв нь хадгалсан үйлчилгээний мэдээлэлд үндэслэнэ.',
          ),
          const SizedBox(height: 18),
          ...List.generate(4, (i) {
            final stage = r.timelineStage;
            final complete = stage > i;
            final current = stage == i;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                complete
                    ? Icons.check_circle_outline
                    : current
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: complete || current
                    ? const Color(0xFF315C47)
                    : const Color(0xFF84908A),
              ),
              title: Text(
                [
                  'Хүсэлт илгээсэн',
                  'Компани баталгаажуулж байна',
                  'Захиалга баталгаажсан',
                  'Хүргэлт',
                ][i],
              ),
              subtitle: Text(
                complete
                    ? 'Дууссан'
                    : current
                    ? 'Одоогийн үе шат'
                    : stage < 0 && r.effectiveStatus != 'draft'
                    ? 'Үе шатны түүх ирээгүй'
                    : 'Хараахан эхлээгүй',
              ),
            );
          }),
          const SizedBox(height: 20),
          ...r.items.map(
            (item) => CartProductRow(
              item: item,
              product: FurnitureStore.instance.products
                  .where((p) => p.id == item.furnitureId)
                  .firstOrNull,
            ),
          ),
          const Divider(),
          Text(
            'Хүсэлтийн дүн: ${formatMoney(r.subtotal)} ₮',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: phone == null
                ? 'Холбоо барих дугаар бүртгээгүй'
                : '${company!.name} · $phone',
            secondary: true,
            onPressed:
                phone == null ||
                    !RegExp(r'^\+?[0-9]{8,15}$')
                        .hasMatch(phone.replaceAll(' ', ''))
                ? null
                : () async {
                    try {
                      if (!await launchUrl(
                        Uri(scheme: 'tel', path: phone.replaceAll(' ', '')),
                      )) {
                        throw StateError('dialer');
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Утасны програм нээгдсэнгүй.'),
                          ),
                        );
                      }
                    }
                  },
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Миний захиалгууд',
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
            ),
          ),
        ],
      );
    },
  );
}
