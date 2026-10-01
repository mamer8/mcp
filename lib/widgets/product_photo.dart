import 'package:flutter/material.dart';

import '../models/product.dart';

class ProductPhoto extends StatelessWidget {
  final Product product;
  final BoxFit fit;

  const ProductPhoto({
    super.key,
    required this.product,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      product.imageUrl,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return ColoredBox(
          color: product.cardColor,
          child: const Center(
            child: SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => ColoredBox(
        color: product.cardColor,
        child: Center(
          child: Icon(product.icon, size: 44, color: const Color(0xFF607078)),
        ),
      ),
    );
  }
}
