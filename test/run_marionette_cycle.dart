import 'dart:convert';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

void main(List<String> args) async {
  final inputUri = args.isNotEmpty ? args[0] : 'http://127.0.0.1:53971/gL1_lHoXMJo=/';
  var wsUri = inputUri.replaceFirst('http://', 'ws://');
  if (!wsUri.endsWith('/ws') && !wsUri.endsWith('/ws/')) {
    if (!wsUri.endsWith('/')) {
      wsUri += '/';
    }
    wsUri += 'ws';
  }

  print('========================================');
  print('Starting QuickStore Full Marionette Cycle');
  print('Connecting to: $wsUri');
  print('========================================');

  final service = await vmServiceConnectUri(wsUri);
  final vm = await service.getVM();
  final isolateId = vm.isolates!.first.id!;

  Future<void> tapKey(String key) async {
    print('👉 Tapping Key: $key');
    await service.callServiceExtension(
      'ext.flutter.marionette.tap',
      isolateId: isolateId,
      args: {'key': key},
    );
    await Future.delayed(const Duration(milliseconds: 600));
  }

  Future<void> enterText(String key, String text) async {
    print('✍️ Entering "$text" into Key: $key');
    await service.callServiceExtension(
      'ext.flutter.marionette.enterText',
      isolateId: isolateId,
      args: {'key': key, 'input': text},
    );
    await Future.delayed(const Duration(milliseconds: 600));
  }

  try {
    // 1. Filter Category: Electronics
    print('\n[Step 1] Filtering by category "Electronics"...');
    await tapKey('chip_category_Electronics');

    // 2. Reset Filter
    print('\n[Step 2] Resetting filter to "All"...');
    await tapKey('chip_category_All');

    // 3. Search for a product
    print('\n[Step 3] Searching for "Watch"...');
    await enterText('input_search_products', 'Watch');
    await Future.delayed(const Duration(milliseconds: 500));
    await enterText('input_search_products', '');

    // 4. Toggle Favorite
    print('\n[Step 4] Toggling Favorite on product p1...');
    await tapKey('btn_favorite_p1');

    // 5. Add to Cart
    print('\n[Step 5] Adding items to Cart...');
    await tapKey('btn_add_to_cart_p1');
    await tapKey('btn_add_to_cart_p2');

    // 6. Open Cart
    print('\n[Step 6] Navigating to Cart...');
    await tapKey('nav_cart');

    // 7. Increment Quantity
    print('\n[Step 7] Incrementing item quantity in Cart...');
    await tapKey('btn_cart_inc_p1');

    // 8. Open Checkout
    print('\n[Step 8] Opening Checkout BottomSheet...');
    await tapKey('btn_checkout_open');

    // 9. Fill Checkout Form
    print('\n[Step 9] Entering Customer info...');
    await enterText('input_checkout_name', 'Amer Ahmed');
    await enterText('input_checkout_address', 'Dokki, Giza');

    // 10. Confirm Order
    print('\n[Step 10] Placing Order...');
    await tapKey('btn_confirm_place_order');

    // 11. Dismiss Dialog
    print('\n[Step 11] Confirming dialog...');
    await tapKey('btn_order_success_ok');

    print('\n🎉 Full Application Cycle Completed Successfully via Marionette!');
  } catch (e, stack) {
    print('❌ Error during Marionette cycle: $e\n$stack');
  } finally {
    service.dispose();
  }
}
