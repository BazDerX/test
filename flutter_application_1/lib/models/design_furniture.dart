import 'ai_generation_job.dart';

/// Catalog data is optional: image generation alone cannot establish prices.
class DesignFurniture {
  const DesignFurniture({
    required this.name,
    required this.quantity,
    this.unitPrice,
  });
  final String name;
  final int quantity;
  final int? unitPrice;
  static List<DesignFurniture>? fromJob(AiGenerationJob job) {
    final records = job.parameters['furniture'];
    if (records is! List) return null;
    final result = <DesignFurniture>[];
    for (final record in records) {
      if (record is! Map || record['name'] is! String) return null;
      final quantity = record['quantity'] ?? 1;
      final price = record['unit_price_mnt'];
      if (quantity is! int ||
          quantity <= 0 ||
          (price != null && (price is! int || price < 0))) {
        return null;
      }
      result.add(
        DesignFurniture(
          name: record['name'] as String,
          quantity: quantity,
          unitPrice: price as int?,
        ),
      );
    }
    return result;
  }

  static int? total(List<DesignFurniture>? items) {
    if (items == null || items.any((item) => item.unitPrice == null)) {
      return null;
    }
    return items.fold<int>(
      0,
      (sum, item) => sum + item.quantity * item.unitPrice!,
    );
  }
}
