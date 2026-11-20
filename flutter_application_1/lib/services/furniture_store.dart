import 'package:flutter/foundation.dart';

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/order_request.dart';

import '../models/furniture.dart';

/// Local catalog and session state. Replace catalog loading with a repository
/// when the furniture backend is ready; UI does not depend on HTTP.
class FurnitureStore extends ChangeNotifier {
  FurnitureStore({List<Furniture>? products})
    : products = List.unmodifiable(products ?? sampleFurniture);
  static final instance = FurnitureStore();
  final List<Furniture> products;
  final Set<String> _favorites = {};
  final Map<String, int> _cart = {};
  final Map<String, int> _prices = {};
  final Map<String, String> _companies = {};
  Future<void> _writes = Future.value();
  bool _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  String? persistenceError;
  Future<void> loadCart() async {
    final raw = (await SharedPreferences.getInstance()).getString(
      'sanaa.cart.v1',
    );
    if (raw == null) return;
    final records = (jsonDecode(raw) as List)
        .map((j) => CartItem.fromJson(Map<String, dynamic>.from(j as Map)))
        .toList();
    _cart.clear();
    _prices.clear();
    _companies.clear();
    for (final item in records) {
      if (item.quantity > 0 && item.unitPrice >= 0) {
        _cart[item.furnitureId] = item.quantity;
        _prices[item.furnitureId] = item.unitPrice;
        _companies[item.furnitureId] = item.companyId;
      }
    }
    notifyListeners();
  }

  List<CartItem> get cartItems => _cart.entries
      .map(
        (e) => CartItem(
          furnitureId: e.key,
          companyId: _companies[e.key]!,
          quantity: e.value,
          unitPrice: _prices[e.key]!,
        ),
      )
      .toList();
  void _persist() {
    final raw = jsonEncode(cartItems.map((i) => i.toJson()).toList());
    _writes = _writes.then((_) async {
      try {
        if (!await (await SharedPreferences.getInstance()).setString(
          'sanaa.cart.v1',
          raw,
        )) {
          throw StateError('storage');
        }
        persistenceError = null;
      } catch (_) {
        persistenceError = 'Сагсыг төхөөрөмжид хадгалж чадсангүй.';
      }
      if (!_disposed) notifyListeners();
    });
  }

  Future<void> flushCart() => _writes;
  FurnitureFilters _filters = const FurnitureFilters();
  FurnitureSort _sort = FurnitureSort.recommended;
  String _query = '';
  FurnitureFilters get filters => _filters;
  FurnitureSort get sort => _sort;
  String get query => _query;
  int get favoriteCount => _favorites.length;
  int get cartCount => _cart.values.fold(0, (sum, quantity) => sum + quantity);
  Map<String, int> get cart => Map.unmodifiable(_cart);
  int get cartTotal => cartItems.fold(0, (sum, item) => sum + item.total);
  bool isFavorite(String id) => _favorites.contains(id);
  void toggleFavorite(String id) {
    if (!_favorites.add(id)) {
      _favorites.remove(id);
    }
    notifyListeners();
  }

  void addToCart(String id) {
    if (!products.any((item) => item.id == id)) return;
    final item = products.firstWhere((p) => p.id == id);
    _prices.putIfAbsent(id, () => item.price);
    _companies.putIfAbsent(id, () => item.orderCompanyId);
    _cart.update(id, (quantity) => quantity + 1, ifAbsent: () => 1);
    notifyListeners();
    _persist();
  }

  void removeFromCart(String id) {
    final quantity = _cart[id];
    if (quantity == null) return;
    if (quantity > 1) {
      _cart[id] = quantity - 1;
    }
    notifyListeners();
    _persist();
  }

  void deleteCartItem(String id) {
    _cart.remove(id);
    _prices.remove(id);
    _companies.remove(id);
    notifyListeners();
    _persist();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setSort(FurnitureSort value) {
    _sort = value;
    notifyListeners();
  }

  void applyFilters(FurnitureFilters value) {
    _filters = value;
    notifyListeners();
  }

  List<Furniture> matching(FurnitureFilters filters, {String? query}) {
    final search = (query ?? _query).trim().toLowerCase();
    return products
        .where(
          (item) =>
              filters.matches(item) && item.name.toLowerCase().contains(search),
        )
        .toList();
  }

  List<Furniture> get visibleProducts {
    final result = matching(filters);
    if (_sort != FurnitureSort.recommended) {
      result.sort(
        (a, b) => _sort == FurnitureSort.lowestPrice
            ? a.price.compareTo(b.price)
            : b.price.compareTo(a.price),
      );
    }
    return result;
  }
}

const sampleFurniture = [
  Furniture(
    id: 'cloud-sofa',
    name: 'Үүл буйдан',
    price: 1290000,
    category: 'Буйдан',
    company: 'Гэр студи',
    companyId: 'ger-studio',
    imagePaths: ['assets/images/sofa.png'],
    description: 'Зөөлөн хэлбэр, дулаан мэдрэмж. Жижиг зочны өрөөнд зориулсан хоёр хүний тухтай буйдан.',
    widthCm: 180,
    depthCm: 86,
    heightCm: 76,
    material: 'Букле даавуу, царс мод',
    color: 'Цөцгий',
    warrantyMonths: 24,
  ),
  Furniture(
    id: 'round-table',
    name: 'Тойрог ширээ',
    price: 389000,
    category: 'Ширээ',
    company: 'Гэр студи',
    companyId: 'ger-studio',
    imagePaths: ['assets/images/coffee_table.png'],
    description: 'Байгалийн модны дулаан өнгөтэй дугуй ширээ. Амрах хэсэгт тохиромжтой авсаархан загвар.',
    widthCm: 80,
    depthCm: 80,
    heightCm: 40,
    material: 'Царс мод',
    color: 'Модон',
    warrantyMonths: 12,
  ),
  Furniture(
    id: 'number-chair',
    name: 'Номер сандал',
    price: 590000,
    category: 'Сандал',
    company: 'Мод урлан',
    companyId: 'mod-workshop',
    imagePaths: ['assets/images/catalog_chair.png'],
    description: 'Модон түшлэг, зөөлөн суудалтай амралтын сандал. Унших болон амрах буланд тохирно.',
    widthCm: 66,
    depthCm: 74,
    heightCm: 80,
    material: 'Царс мод, даавуу',
    color: 'Цөцгий',
    warrantyMonths: 18,
  ),
  Furniture(
    id: 'ray-lamp',
    name: 'Туяа гэрэл',
    price: 189000,
    category: 'Гэрэл',
    company: 'Гэр студи',
    companyId: 'ger-studio',
    imagePaths: ['assets/images/catalog_lamp.png'],
    description: 'Тасалгаанд зөөлөн дулаан гэрэл түгээх босоо гэрэл. Буйдан болон сандлын хажууд байрлуулахад тохиромжтой.',
    widthCm: 35,
    depthCm: 35,
    heightCm: 155,
    material: 'Мод, даавуу',
    color: 'Модон',
    warrantyMonths: 12,
  ),
];
