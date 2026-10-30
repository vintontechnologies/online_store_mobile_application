
class Product {
  final int id;
  final String name;
  final String slug;
  final String description;
  final double price;
  final int stockQuantity;
  final String categoryName;
  final List<String> imageUrls;

  const Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.price,
    required this.stockQuantity,
    required this.categoryName,
    required this.imageUrls,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    final images = json['images'];

    final imageUrls = images is List
        ? images
            .whereType<Map<String, dynamic>>()
            .map((image) => image['image']?.toString() ?? '')
            .where((url) => url.isNotEmpty)
            .toList()
        : <String>[];

    return Product(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? 'Unnamed product',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0,
      stockQuantity:
          int.tryParse(json['stock_quantity'].toString()) ?? 0,
      categoryName: category is Map
          ? category['name']?.toString() ?? 'Uncategorized'
          : 'Uncategorized',
      imageUrls: imageUrls,
    );
  }

  String? get primaryImageUrl =>
      imageUrls.isEmpty ? null : imageUrls.first;
}
