import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mcp/main.dart';
import 'package:mcp/data/demo_products.dart';
import 'package:mcp/models/product.dart';
import 'package:mcp/models/sketchfab_model.dart';
import 'package:mcp/services/sketchfab_catalog_service.dart';

Future<List<SketchfabModel>> _emptyModelLoader(Product product) async =>
    const [];

void main() {
  test(
    'Sketchfab search keeps matching open models and filters unsuitable assets',
    () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters['license'], 'by');
        expect(request.url.queryParameters['downloadable'], 'true');
        return http.Response(
          jsonEncode({
            'results': [
              {
                'uid': 'iphone-13-pro',
                'name': 'iPhone 13 Pro',
                'likeCount': 12,
                'viewCount': 240,
                'embedUrl': 'https://sketchfab.com/models/iphone-13-pro/embed',
                'viewerUrl': 'https://sketchfab.com/3d-models/iphone-13-pro',
                'tags': [
                  {'name': 'iphone13pro'},
                ],
                'user': {
                  'displayName': 'Demo Creator',
                  'profileUrl': 'https://sketchfab.com/demo-creator',
                },
                'license': {'label': 'CC Attribution'},
                'thumbnails': {
                  'images': [
                    {'url': 'https://example.com/iphone.webp'},
                  ],
                },
              },
              {
                'uid': 'museum-scan',
                'name': 'Egyptian Museum Scan',
                'tags': [],
                'description': 'Captured using an iPhone 13 Pro',
                'license': {'label': 'CC Attribution'},
              },
              {
                'uid': 'ai-iphone',
                'name': 'iPhone 13 Pro AI Generated',
                'tags': [
                  {'name': 'iphone13pro'},
                  {'name': 'ai-generated'},
                ],
                'archives': {
                  'glb': {'size': 1024},
                },
              },
              {
                'uid': 'oversized-iphone',
                'name': 'iPhone 13 Pro Oversized',
                'tags': [],
                'archives': {
                  'glb': {'size': 60 * 1024 * 1024},
                },
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final service = SketchfabCatalogService(client: client);

      final models = await service.searchModels(
        demoProducts.firstWhere((product) => product.id == 'p9'),
      );

      expect(models, hasLength(1));
      expect(models.single.name, 'iPhone 13 Pro');
      expect(models.single.authorName, 'Demo Creator');
      expect(models.single.license, 'CC Attribution');
      client.close();
    },
  );

  test('Sketchfab matching rejects partial title matches', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'results': [
            {
              'uid': 'table-model',
              'name': 'Low Poly Table for Mockups',
              'tags': [
                {'name': 'tablet'},
              ],
            },
            {
              'uid': 'tablet-model',
              'name': 'Modern Tablet 3D Model',
              'tags': [],
            },
          ],
        }),
        200,
      ),
    );
    final service = SketchfabCatalogService(client: client);

    final models = await service.searchModels(
      demoProducts.firstWhere((product) => product.id == 'p5'),
    );

    expect(models.map((model) => model.uid), ['tablet-model']);
    client.close();
  });

  testWidgets('QuickStore Full Application E2E Shopping Cycle Test', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // 1. Launch the application
    await tester.pumpWidget(
      StoreApp(home: StoreMainScreen(modelLoader: _emptyModelLoader)),
    );
    await tester.pumpAndSettle();

    // Verify home screen and products loaded
    expect(find.text('QuickStore'), findsOneWidget);
    expect(find.text('Wireless Headphones'), findsOneWidget);
    expect(find.text('Smart Watch Series 8'), findsOneWidget);

    // Open product details and verify the no-match fallback.
    await tester.tap(find.byKey(const Key('btn_product_details_p1')));
    await tester.pumpAndSettle();
    expect(
      find.text('لم يتم العثور على موديل 3D مفتوح ومطابق لهذا المنتج.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('btn_detail_add_to_cart')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 2. Filter by Category: Electronics
    final electronicsChip = find.byKey(const Key('chip_category_Electronics'));
    expect(electronicsChip, findsOneWidget);
    await tester.tap(electronicsChip);
    await tester.pumpAndSettle();

    // Verify Electronics products visible, others filtered out
    expect(find.text('Ultra-Slim Tablet 11"'), findsOneWidget);
    expect(find.text('iPhone 13 Pro'), findsOneWidget);
    expect(find.text('Samsung Galaxy S10'), findsOneWidget);
    expect(find.text('Wireless Headphones'), findsNothing);

    // Reset filter to All
    await tester.tap(find.byKey(const Key('chip_category_All')));
    await tester.pumpAndSettle();
    expect(find.text('Wireless Headphones'), findsOneWidget);

    await tester.tap(find.byKey(const Key('chip_category_Audio')));
    await tester.pumpAndSettle();
    expect(find.text('Apple AirPods'), findsOneWidget);
    expect(find.text('Apple AirPods Max Silver'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chip_category_All')));
    await tester.pumpAndSettle();

    // 3. Search for a product
    final searchField = find.byKey(const Key('input_search_products'));
    await tester.enterText(searchField, 'Watch');
    await tester.pumpAndSettle();
    expect(find.text('Smart Watch Series 8'), findsOneWidget);
    expect(find.text('Wireless Headphones'), findsNothing);

    // Clear search
    await tester.enterText(searchField, '');
    await tester.pumpAndSettle();
    expect(find.text('Wireless Headphones'), findsOneWidget);

    // 4. Toggle Favorite / Wishlist on p1 (Wireless Headphones)
    final favButton = find.byKey(const Key('btn_favorite_p1'));
    expect(favButton, findsOneWidget);
    await tester.tap(favButton); // Removes p1 from favorites
    await tester.pumpAndSettle();

    await tester.tap(favButton); // Adds p1 back to favorites
    await tester.pumpAndSettle();

    // Check Favorites tab
    final navFavorites = find.byKey(const Key('nav_favorites'));
    await tester.tap(navFavorites);
    await tester.pumpAndSettle();
    expect(find.text('Wireless Headphones'), findsOneWidget);

    // 5. Add Products to Cart from Home
    final navHome = find.byKey(const Key('nav_home'));
    await tester.tap(navHome);
    await tester.pumpAndSettle();

    final addToCartP1 = find.byKey(const Key('btn_add_to_cart_p1'));
    await tester.tap(addToCartP1);
    await tester.pumpAndSettle();

    final addToCartP2 = find.byKey(const Key('btn_add_to_cart_p2'));
    await tester.tap(addToCartP2);
    await tester.pumpAndSettle();

    // 6. Navigate to Cart & Modify Quantity
    final navCart = find.byKey(const Key('nav_cart'));
    await tester.tap(navCart);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('list_cart_items')), findsOneWidget);
    expect(find.text('Wireless Headphones'), findsOneWidget);
    expect(find.text('Smart Watch Series 8'), findsOneWidget);

    // Increment p1 quantity
    final incP1 = find.byKey(const Key('btn_cart_inc_p1'));
    await tester.tap(incP1);
    await tester.pumpAndSettle();
    expect(find.text('2'), findsWidgets); // Found in cart count and badge

    // 7. Proceed to Checkout
    final checkoutButton = find.byKey(const Key('btn_checkout_open'));
    await tester.tap(checkoutButton);
    await tester.pumpAndSettle();

    // Enter Checkout Form Data
    final nameInput = find.byKey(const Key('input_checkout_name'));
    final addressInput = find.byKey(const Key('input_checkout_address'));
    expect(nameInput, findsOneWidget);
    expect(addressInput, findsOneWidget);

    await tester.enterText(nameInput, 'Amer Ahmed');
    await tester.enterText(addressInput, 'Dokki, Giza');
    await tester.pumpAndSettle();

    // Place Order
    final confirmOrderBtn = find.byKey(const Key('btn_confirm_place_order'));
    await tester.tap(confirmOrderBtn);
    await tester.pumpAndSettle();

    // 8. Verify Order Confirmation Dialog
    expect(find.text('تم تأكيد الطلب بنجاح! 🎉'), findsOneWidget);
    expect(find.text('الاسم: Amer Ahmed'), findsOneWidget);
    expect(find.text('العنوان: Dokki, Giza'), findsOneWidget);

    // Close Dialog
    final dialogOkBtn = find.byKey(const Key('btn_order_success_ok'));
    await tester.tap(dialogOkBtn);
    await tester.pumpAndSettle();

    // 9. Verify Order History Tab
    expect(find.text('قيد التجهيز 🚚'), findsOneWidget);
    expect(find.textContaining('Amer Ahmed'), findsOneWidget);
    expect(find.textContaining('Dokki, Giza'), findsOneWidget);
  });
}
