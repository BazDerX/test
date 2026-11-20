class CartItem {
  const CartItem({
    required this.furnitureId,
    required this.companyId,
    required this.quantity,
    required this.unitPrice,
  });
  final String furnitureId, companyId;
  final int quantity, unitPrice;
  int get total => quantity * unitPrice;
  Map<String, dynamic> toJson() => {
    'furniture_id': furnitureId,
    'company_id': companyId,
    'quantity': quantity,
    'unit_price': unitPrice,
  };
  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
    furnitureId: j['furniture_id'] as String,
    companyId: j['company_id'] as String,
    quantity: j['quantity'] as int,
    unitPrice: j['unit_price'] as int,
  );
}

class OrderRequest {
  const OrderRequest({
    required this.orderId,
    required this.companyId,
    required this.customerName,
    required this.phone,
    required this.cityDistrict,
    required this.deliveryAddress,
    required this.items,
    required this.createdAt,
    this.email = '',
    this.additionalNotes = '',
    this.status = 'draft',
    this.deliveryStatus = 'local_draft',
  });
  final String orderId,
      companyId,
      customerName,
      phone,
      cityDistrict,
      deliveryAddress,
      email,
      additionalNotes,
      status;
  final DateTime createdAt;
  final String deliveryStatus;
  String get effectiveStatus =>
      deliveryStatus == 'local_draft' ? 'draft' : status;
  String get statusLabel =>
      const {
        'draft': 'Хүсэлт түр хадгалагдсан',
        'submitted': 'Илгээсэн',
        'reviewing': 'Компани шалгаж байна',
        'confirmed': 'Захиалга баталгаажсан',
        'delivering': 'Хүргэлтэд гарсан',
        'delivered': 'Хүргэгдсэн',
        'cancelled': 'Цуцлагдсан',
        'rejected': 'Татгалзсан',
      }[effectiveStatus] ??
      'Төлөв тодорхойгүй';
  int get timelineStage =>
      const {
        'draft': -1,
        'submitted': 0,
        'reviewing': 1,
        'confirmed': 2,
        'delivering': 3,
        'delivered': 4,
      }[effectiveStatus] ??
      -1;
  final List<CartItem> items;
  int get subtotal => items.fold(0, (sum, item) => sum + item.total);
  Map<String, dynamic> toJson() => {
    'order_id': orderId,
    'company_id': companyId,
    'customer_name': customerName,
    'phone': phone,
    'city_district': cityDistrict,
    'delivery_address': deliveryAddress,
    'email': email,
    'notes': additionalNotes,
    'status': status,
    'delivery_status': deliveryStatus,
    'created_at': createdAt.toUtc().toIso8601String(),
    'subtotal': subtotal,
    'items': items.map((i) => i.toJson()).toList(),
  };
  factory OrderRequest.fromJson(Map<String, dynamic> j) => OrderRequest(
    orderId: j['order_id'] as String,
    companyId: j['company_id'] as String,
    customerName: j['customer_name'] as String,
    phone: j['phone'] as String,
    cityDistrict: j['city_district'] as String,
    deliveryAddress: j['delivery_address'] as String,
    email: j['email'] as String? ?? '',
    additionalNotes: j['notes'] as String? ?? '',
    status: j['status'] as String,
    deliveryStatus: j['delivery_status'] as String? ?? 'local_draft',
    createdAt: DateTime.parse(j['created_at'] as String),
    items: (j['items'] as List)
        .map((i) => CartItem.fromJson(Map<String, dynamic>.from(i as Map)))
        .toList(),
  );
}
