import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp/main.dart';

void main() {
  testWidgets('QuickStore Full Application E2E Shopping Cycle Test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // 1. Launch the application
    await tester.pumpWidget(const StoreApp());
    await tester.pumpAndSettle();

    // Verify home screen and products loaded
    expect(find.text('QuickStore'), findsOneWidget);
    expect(find.text('Wireless Headphones'), findsOneWidget);
    expect(find.text('Smart Watch Series 8'), findsOneWidget);

    // 2. Filter by Category: Electronics
    final electronicsChip = find.byKey(const Key('chip_category_Electronics'));
    expect(electronicsChip, findsOneWidget);
    await tester.tap(electronicsChip);
    await tester.pumpAndSettle();

    // Verify Electronics products visible, others filtered out
    expect(find.text('Ultra-Slim Tablet 11"'), findsOneWidget);
    expect(find.text('Wireless Headphones'), findsNothing);

    // Reset filter to All
    await tester.tap(find.byKey(const Key('chip_category_All')));
    await tester.pumpAndSettle();
    expect(find.text('Wireless Headphones'), findsOneWidget);

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
