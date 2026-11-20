class Furniture {
  const Furniture({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.company,
    required this.imagePaths,
    required this.widthCm,
    required this.depthCm,
    required this.heightCm,
    required this.material,
    required this.color,
    required this.warrantyMonths,
    this.has3DModel = false,
    this.model3DPath,
    this.companyId = '',
  });
  final String id, name, description, category, company, material, color;
  final int price, warrantyMonths;
  final List<String> imagePaths;
  final double widthCm, depthCm, heightCm;
  final bool has3DModel;
  final String? model3DPath;
  final String companyId;
  String get orderCompanyId =>
      companyId.isEmpty ? 'local:${Uri.encodeComponent(company)}' : companyId;
  bool get modelAvailable =>
      has3DModel && model3DPath != null && model3DPath!.isNotEmpty;
}

enum FurnitureSort { recommended, lowestPrice, highestPrice }

class FurnitureFilters {
  const FurnitureFilters({
    this.category,
    this.minPrice = 0,
    this.maxPrice,
    this.maxWidth,
    this.maxDepth,
    this.maxHeight,
    this.materials = const {},
    this.colors = const {},
    this.company,
    this.only3D = false,
  });
  final String? category, company;
  final int minPrice;
  final int? maxPrice;
  final double? maxWidth, maxDepth, maxHeight;
  final Set<String> materials, colors;
  final bool only3D;
  int get activeCount => [
    category != null,
    minPrice > 0 || maxPrice != null,
    maxWidth != null,
    maxDepth != null,
    maxHeight != null,
    materials.isNotEmpty,
    colors.isNotEmpty,
    company != null,
    only3D,
  ].where((active) => active).length;
  bool matches(Furniture item) =>
      (category == null || item.category == category) &&
      item.price >= minPrice &&
      (maxPrice == null || item.price <= maxPrice!) &&
      (maxWidth == null || item.widthCm <= maxWidth!) &&
      (maxDepth == null || item.depthCm <= maxDepth!) &&
      (maxHeight == null || item.heightCm <= maxHeight!) &&
      (materials.isEmpty ||
          materials.any(
            (material) =>
                item.material.toLowerCase().contains(material.toLowerCase()),
          )) &&
      (colors.isEmpty || colors.contains(item.color)) &&
      (company == null || item.company == company) &&
      (!only3D || item.modelAvailable);
  FurnitureFilters withCategory(String? value) => FurnitureFilters(
    category: value,
    minPrice: minPrice,
    maxPrice: maxPrice,
    maxWidth: maxWidth,
    maxDepth: maxDepth,
    maxHeight: maxHeight,
    materials: materials,
    colors: colors,
    company: company,
    only3D: only3D,
  );
}
