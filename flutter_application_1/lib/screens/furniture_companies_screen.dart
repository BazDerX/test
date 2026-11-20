import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/furniture_company.dart';
import '../models/furniture.dart';
import '../services/furniture_store.dart';
import '../widgets/design_screen_layout.dart';
import '../widgets/furniture_navigation.dart';
import '../widgets/primary_button.dart';
import 'furniture_listing_screen.dart';

class FurnitureCompaniesScreen extends StatefulWidget {
  const FurnitureCompaniesScreen({super.key, this.companyId, this.store});
  final String? companyId;
  final FurnitureStore? store;
  @override
  State<FurnitureCompaniesScreen> createState() => _CompaniesState();
}

class _CompaniesState extends State<FurnitureCompaniesScreen> {
  String query = '', location = 'Бүгд';
  @override
  Widget build(BuildContext context) {
    final store = widget.store ?? FurnitureStore.instance;
    final companies = furnitureCompanies
        .where(
          (c) =>
              (widget.companyId == null || c.id == widget.companyId) &&
              (c.name.toLowerCase().contains(query.toLowerCase()) ||
                  c.location.toLowerCase().contains(query.toLowerCase())) &&
              (location == 'Бүгд' || c.location.contains(location)),
        )
        .toList();
    return DesignScreenLayout(
      title: 'Тавилгын компаниуд',
      bottomNavigationBar: const FurnitureNavigation(),
      children: [
        const Text('Компани хайх'),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Нэр эсвэл байршил',
            suffixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => query = v),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: ['Бүгд', 'Улаанбаатар', 'Хан-Уул', 'Баянзүрх']
              .map(
                (v) => ChoiceChip(
                  label: Text(v),
                  selected: location == v,
                  onSelected: (_) => setState(() => location = v),
                ),
              )
              .toList(),
        ),
        const Text(
          'Жишиг компаниуд · Бодит бизнесийн баталгаажсан бүртгэл биш.',
        ),
        const SizedBox(height: 16),
        if (companies.isEmpty) const Text('Тохирох компани олдсонгүй.'),
        ...companies.map((c) {
          final products = store.products
              .where((p) => p.company == c.name)
              .toList();
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFF315C47)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 1.5,
                    child: Image.asset(c.cover, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: Text(c.name.substring(0, 1))),
                  title: Text(
                    c.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(c.location),
                  trailing: c.verified
                      ? const Icon(Icons.verified_outlined)
                      : null,
                ),
                Text(
                  '${products.map((p) => p.category).toSet().join(' · ')} · ${products.length} бүтээгдэхүүн',
                ),
                const SizedBox(height: 12),
                Text(c.description),
                const SizedBox(height: 12),
                Text(c.address),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Тавилгуудыг үзэх · ${products.length}',
                  onPressed: () {
                    store.applyFilters(FurnitureFilters(company: c.name));
                    store.setQuery('');
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FurnitureListingScreen(store: store),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: c.phone == null
                      ? 'Холбоо барих дугаар бүртгээгүй'
                      : 'Холбогдох · ${c.phone}',
                  secondary: true,
                  onPressed: c.phone == null
                      ? null
                      : () async {
                          final phone = c.phone!.replaceAll(
                            RegExp(r'[^0-9+]'),
                            '',
                          );
                          if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(phone)) {
                            return;
                          }
                          try {
                            if (!await launchUrl(
                              Uri(scheme: 'tel', path: phone),
                            )) {
                              throw PlatformException(code: 'dialer');
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
              ],
            ),
          );
        }),
      ],
    );
  }
}
