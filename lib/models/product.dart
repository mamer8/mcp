import 'package:flutter/material.dart';

class Product {
  final String id;
  final String title;
  final String category;
  final double price;
  final double rating;
  final IconData icon;
  final Color cardColor;
  final String imageUrl;
  final String? brand;
  final String? description;
  final String? model3dSearchTerm;
  final List<String> model3dKeywords;

  const Product({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    required this.rating,
    required this.icon,
    required this.cardColor,
    required this.imageUrl,
    this.brand,
    this.description,
    this.model3dSearchTerm,
    this.model3dKeywords = const [],
  });
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}
