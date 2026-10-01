import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/sketchfab_model.dart';
import '../services/sketchfab_catalog_service.dart';
import '../widgets/product_photo.dart';
import '../widgets/sketchfab_3d_viewer.dart';

typedef SketchfabModelLoader =
    Future<List<SketchfabModel>> Function(Product product);

class ProductDetailsPage extends StatefulWidget {
  final Product product;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onAddToCart;
  final SketchfabModelLoader? modelLoader;

  const ProductDetailsPage({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onAddToCart,
    this.modelLoader,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  SketchfabCatalogService? _ownedService;
  late Future<List<SketchfabModel>> _modelsFuture;
  String? _selectedModelUid;

  @override
  void initState() {
    super.initState();
    if (widget.modelLoader == null) {
      _ownedService = SketchfabCatalogService();
    }
    _modelsFuture = _loadModels();
  }

  Future<List<SketchfabModel>> _loadModels() =>
      widget.modelLoader?.call(widget.product) ??
      _ownedService!.searchModels(widget.product);

  @override
  void dispose() {
    _ownedService?.close();
    super.dispose();
  }

  Widget _buildModelPreview() {
    return FutureBuilder<List<SketchfabModel>>(
      future: _modelsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _previewMessage(
            'جاري البحث عن موديلات 3D مطابقة...',
            loading: true,
          );
        }
        if (snapshot.hasError) {
          return _previewMessage(
            'تعذر تحميل كتالوج 3D. تحقق من الإنترنت وحاول مرة أخرى.',
            onRetry: () => setState(() => _modelsFuture = _loadModels()),
          );
        }

        final models = snapshot.data ?? const [];
        if (models.isEmpty) {
          return _previewMessage(
            'لم يتم العثور على موديل 3D مفتوح ومطابق لهذا المنتج.',
          );
        }

        var selectedModel = models.first;
        for (final model in models) {
          if (model.uid == _selectedModelUid) {
            selectedModel = model;
            break;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 330,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Sketchfab3DViewer(
                        key: ValueKey(selectedModel.uid),
                        model: selectedModel,
                      ),
                    ),
                    Positioned(
                      top: 14,
                      left: 14,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.view_in_ar,
                                size: 16,
                                color: Color(0xFF167D7F),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'موديل 3D حقيقي',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (models.length > 1) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<SketchfabModel>(
                key: const Key('select_3d_model'),
                initialValue: selectedModel,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'موديل 3D من الكتالوج',
                  border: OutlineInputBorder(),
                ),
                items: models
                    .map(
                      (model) => DropdownMenuItem(
                        value: model,
                        child: Text(
                          '${model.name} • ${model.authorName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (model) {
                  if (model != null) {
                    setState(() => _selectedModelUid = model.uid);
                  }
                },
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'الموديل: ${selectedModel.name} • صاحب النموذج: ${selectedModel.authorName} • ${selectedModel.license}',
              style: const TextStyle(
                color: Color(0xFF5D686D),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _previewMessage(
    String message, {
    bool loading = false,
    VoidCallback? onRetry,
  }) {
    return SizedBox(
      height: 330,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ProductPhoto(product: widget.product, fit: BoxFit.contain),
            ColoredBox(color: Colors.white.withValues(alpha: 0.82)),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (loading)
                      const CircularProgressIndicator()
                    else
                      const Icon(
                        Icons.view_in_ar_outlined,
                        size: 36,
                        color: Color(0xFF167D7F),
                      ),
                    const SizedBox(height: 12),
                    Text(message, textAlign: TextAlign.center),
                    if (onRetry != null) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        key: const Key('btn_3d_retry'),
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        title: const Text('تفاصيل المنتج'),
        actions: [
          IconButton(
            key: const Key('btn_detail_favorite'),
            tooltip: widget.isFavorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
            onPressed: widget.onToggleFavorite,
            icon: Icon(
              widget.isFavorite ? Icons.favorite : Icons.favorite_border,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _buildModelPreview(),
          const SizedBox(height: 22),
          Text(
            product.category.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF167D7F),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            product.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF202A30),
            ),
          ),
          if (product.brand != null) ...[
            const SizedBox(height: 4),
            Text(
              product.brand!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF5D686D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.star, size: 18, color: Color(0xFFE4A72C)),
              const SizedBox(width: 5),
              Text(
                '${product.rating}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              const Text(
                '(تقييمات تجريبية)',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const Spacer(),
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF167D7F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'عن المنتج',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            product.description ??
                'بيانات المنتج وصورته للتجربة، وموديلات 3D مفتوحة من Sketchfab.',
            style: const TextStyle(height: 1.5, color: Color(0xFF5D686D)),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        child: SizedBox(
          height: 52,
          child: FilledButton.icon(
            key: const Key('btn_detail_add_to_cart'),
            onPressed: widget.onAddToCart,
            icon: const Icon(Icons.add_shopping_cart),
            label: Text('أضف للسلة  •  \$${product.price.toStringAsFixed(2)}'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF167D7F),
            ),
          ),
        ),
      ),
    );
  }
}
