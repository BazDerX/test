import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/order_request.dart';

/// A future FastAPI adapter must return delivered only after server acceptance.
enum RequestDelivery { localDraft, delivered }

abstract interface class OrderRequestService {
  Future<RequestDelivery> submit(OrderRequest request);
}

class LocalOrderRequestService implements OrderRequestService {
  const LocalOrderRequestService();
  static const key = 'sanaa.order.drafts.v1';
  static Future<List<OrderRequest>> drafts() async {
    final raw = (await SharedPreferences.getInstance()).getString(key);
    return raw == null
        ? []
        : (jsonDecode(raw) as List)
              .map(
                (j) =>
                    OrderRequest.fromJson(Map<String, dynamic>.from(j as Map)),
              )
              .toList();
  }

  @override
  Future<RequestDelivery> submit(OrderRequest request) async {
    if (request.items.isEmpty ||
        request.items.any(
          (i) =>
              i.companyId != request.companyId ||
              i.quantity < 1 ||
              i.unitPrice < 0,
        )) {
      throw StateError('Захиалгын өгөгдөл буруу');
    }
    final draft = OrderRequest.fromJson({
      ...request.toJson(),
      'status': 'draft',
      'delivery_status': 'local_draft',
    });
    final values = await drafts();
    final data = [draft, ...values.where((r) => r.orderId != request.orderId)];
    if (!await (await SharedPreferences.getInstance()).setString(
      key,
      jsonEncode(data.map((r) => r.toJson()).toList()),
    )) {
      throw StateError('Хадгалж чадсангүй');
    }
    await OrderHistoryStore.instance.load();
    return RequestDelivery.localDraft;
  }
}

class OrderHistoryStore extends ChangeNotifier {
  static final instance = OrderHistoryStore();
  List<OrderRequest> items = [];
  String? error;
  bool loading = false;
  Future<void> load() async {
    // Routes can request a refresh while their parent is still building.
    await Future<void>.value();
    loading = true;
    error = null;
    notifyListeners();
    try {
      items = await LocalOrderRequestService.drafts();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      error = 'Хүсэлтүүдийг уншиж чадсангүй.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  OrderRequest? find(String id) =>
      items.where((r) => r.orderId == id).firstOrNull;
}
