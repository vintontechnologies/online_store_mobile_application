
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';

class ProductService {
  static const String _productsUrl =
      'https://fullstact-e-com-platform.onrender.com/api/v1/products/';

  Future<List<Product>> fetchProducts() async {
    final uri = Uri.parse(_productsUrl);

    final response = await http
        .get(
          uri,
          headers: const {
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw Exception(
        'Unable to load products. HTTP ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Unexpected products API response.',
      );
    }

    final results = decoded['results'];

    if (results is! List) {
      throw const FormatException(
        'The products API did not return a results list.',
      );
    }

    return results
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .where((product) => product.id > 0)
        .toList();
  }
}
