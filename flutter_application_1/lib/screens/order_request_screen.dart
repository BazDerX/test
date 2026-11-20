import 'package:flutter/material.dart';

import '../models/order_request.dart';
import '../models/design_preferences.dart';
import '../services/furniture_store.dart';
import '../services/order_request_service.dart';
import '../widgets/design_screen_layout.dart';
import '../widgets/primary_button.dart';
import '../widgets/cart_product_row.dart';
import 'order_status_screen.dart';

class OrderRequestScreen extends StatefulWidget {
  const OrderRequestScreen({
    super.key,
    required this.companyId,
    required this.store,
    this.service = const LocalOrderRequestService(),
  });
  final String companyId;
  final FurnitureStore store;
  final OrderRequestService service;
  @override
  State<OrderRequestScreen> createState() => _OrderState();
}

class _OrderState extends State<OrderRequestScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      phone = TextEditingController(),
      address = TextEditingController(),
      email = TextEditingController(),
      notes = TextEditingController();
  String? city;
  bool busy = false, saved = false;
  RequestDelivery? delivery;
  List<CartItem>? receipt;
  late final id = 'request-${DateTime.now().microsecondsSinceEpoch}';
  String? error;
  @override
  void dispose() {
    for (final c in [name, phone, address, email, notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget field(
    String title,
    TextEditingController c, {
    bool required = false,
    TextInputType? keyboard,
    int lines = 1,
    String? Function(String)? validate,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        const SizedBox(height: 8),
        TextFormField(
          controller: c,
          enabled: !busy && !saved,
          maxLines: lines,
          keyboardType: keyboard,
          decoration: const InputDecoration(errorMaxLines: 3),
          validator: (v) {
            if (required && (v ?? '').trim().isEmpty) {
              return '$title оруулна уу.';
            }
            return validate?.call((v ?? '').trim());
          },
        ),
      ],
    ),
  );
  Future<void> submit() async {
    if (busy || saved || !form.currentState!.validate()) return;
    final items = widget.store.cartItems
        .where((i) => i.companyId == widget.companyId)
        .toList();
    if (items.isEmpty) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await widget.service.submit(
        OrderRequest(
          orderId: id,
          companyId: widget.companyId,
          customerName: name.text.trim(),
          phone: phone.text.replaceAll(RegExp(r'[\s-]'), ''),
          cityDistrict: city!,
          deliveryAddress: address.text.trim(),
          email: email.text.trim(),
          additionalNotes: notes.text.trim(),
          items: List.unmodifiable(items),
          createdAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      setState(() {
        saved = true;
        delivery = result;
        receipt = List.unmodifiable(items);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == RequestDelivery.localDraft
                ? 'Хүсэлт түр хадгалагдлаа. Компанид илгээгдээгүй.'
                : 'Хүсэлт амжилттай илгээгдлээ.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Хүсэлтийг хадгалж чадсангүй. Дахин оролдоно уу.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final items =
          receipt ??
          widget.store.cartItems
              .where((i) => i.companyId == widget.companyId)
              .toList();
      final total = items.fold<int>(0, (n, i) => n + i.total);
      final company =
          widget.store.products
              .where((p) => items.any((i) => i.furnitureId == p.id))
              .firstOrNull
              ?.company ??
          'Компани';
      return DesignScreenLayout(
        title: 'Захиалгын хүсэлт',
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EFE7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Text(
                  'Хүсэлтийг энэ компанид илгээхээр бэлтгэнэ. Одоогоор зөвхөн төхөөрөмжид хадгалагдана.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Холбоо барих мэдээлэл',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          Form(
            key: form,
            child: Column(
              children: [
                field('Овог, нэр', name, required: true),
                field(
                  'Утасны дугаар',
                  phone,
                  required: true,
                  keyboard: TextInputType.phone,
                  validate: (v) =>
                      RegExp(r'^(?:\+976)?[5-9][0-9]{7}$')
                          .hasMatch(v.replaceAll(RegExp(r'[\s-]'), ''))
                      ? null
                      : 'Монголын 8 оронтой утасны дугаар оруулна уу.',
                ),
                DropdownButtonFormField<String>(
                  initialValue: city,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Хот / дүүрэг'),
                  items:
                      [
                            'УБ · Хан-Уул',
                            'УБ · Баянзүрх',
                            'УБ · Баянгол',
                            'УБ · Сүхбаатар',
                            'УБ · Чингэлтэй',
                            'УБ · Сонгинохайрхан',
                            'УБ · Налайх',
                            'УБ · Багануур',
                            'УБ · Багахангай',
                            'Орон нутаг',
                          ]
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                  onChanged: busy || saved
                      ? null
                      : (v) => setState(() => city = v),
                  validator: (v) =>
                      v == null ? 'Хот / дүүргээ сонгоно уу.' : null,
                ),
                const SizedBox(height: 18),
                field('Хүргэлтийн хаяг', address, required: true, lines: 2),
                field(
                  'Имэйл',
                  email,
                  keyboard: TextInputType.emailAddress,
                  validate: (v) =>
                      v.isEmpty ||
                          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)
                      ? null
                      : 'Имэйл хаягаа зөв оруулна уу.',
                ),
                field('Нэмэлт тайлбар', notes, lines: 2),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Таны сонголт · ${items.fold<int>(0, (n, i) => n + i.quantity)} бараа',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                ...items.map(
                  (i) => CartProductRow(
                    item: i,
                    product: widget.store.products
                        .where((p) => p.id == i.furnitureId)
                        .firstOrNull,
                  ),
                ),
                const Divider(),
                Text(
                  'Нийт дүн: ${formatMoney(total)} ₮',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EFE7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              'Одоогоор төлбөр төлөхгүй. Хүргэлтийн үнэ, хугацааг компани тантай холбогдож баталгаажуулна.',
            ),
          ),
          const SizedBox(height: 20),
          if (error != null) Text(error!),
          if (saved)
            Text(
              delivery == RequestDelivery.delivered
                  ? 'Хүсэлт амжилттай илгээгдлээ.'
                  : 'Хүсэлт түр хадгалагдлаа. Компанид илгээгдээгүй. Дахин илгээхийн тулд серверийн холболт шаардлагатай.',
            ),
          if (saved)
            TextButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderStatusScreen(orderId: id),
                ),
              ),
              child: const Text('Хүсэлтийн төлөв харах'),
            ),
          PrimaryButton(
            label: saved
                ? 'Хүсэлт хадгалагдсан'
                : 'Хүсэлт илгээх · ${formatMoney(total)} ₮',
            loading: busy,
            onPressed: saved || items.isEmpty ? null : submit,
          ),
        ],
      );
    },
  );
}
