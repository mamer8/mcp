import 'package:flutter/material.dart';

import '../data/demo_products.dart';
import '../models/order_model.dart';
import '../models/product.dart';
import 'product_details_page.dart';
import '../widgets/product_card.dart';
import '../widgets/product_photo.dart';

class StoreMainScreen extends StatefulWidget {
  final SketchfabModelLoader? modelLoader;

  const StoreMainScreen({super.key, this.modelLoader});

  @override
  State<StoreMainScreen> createState() => _StoreMainScreenState();
}

class _StoreMainScreenState extends State<StoreMainScreen> {
  int _currentTabIndex = 0;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Electronics',
    'Fashion',
    'Watches',
    'Audio',
    'Gaming',
  ];

  final List<Product> _allProducts = demoProducts;

  final Set<String> _favoriteProductIds = {'p1', 'p2'};
  final Map<String, CartItem> _cart = {};
  final List<OrderModel> _ordersHistory = [];

  // Computed Properties
  List<Product> get _filteredProducts {
    return _allProducts.where((p) {
      final matchesCategory =
          _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchesSearch =
          _searchQuery.isEmpty ||
          p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  int get _cartItemCount =>
      _cart.values.fold(0, (sum, item) => sum + item.quantity);

  double get _cartTotalAmount => _cart.values.fold(
    0.0,
    (sum, item) => sum + (item.product.price * item.quantity),
  );

  void _toggleFavorite(String productId) {
    setState(() {
      if (_favoriteProductIds.contains(productId)) {
        _favoriteProductIds.remove(productId);
      } else {
        _favoriteProductIds.add(productId);
      }
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _favoriteProductIds.contains(productId)
              ? 'تمت الإضافة للمفضلة ❤️'
              : 'تمت الإزالة من المفضلة',
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addToCart(Product product) {
    setState(() {
      if (_cart.containsKey(product.id)) {
        _cart[product.id]!.quantity++;
      } else {
        _cart[product.id] = CartItem(product: product);
      }
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تمت إضافة "${product.title}" إلى السلة 🛒'),
        action: SnackBarAction(
          label: 'عرض السلة',
          onPressed: () => setState(() => _currentTabIndex = 2),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openProductDetails(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailsPage(
          product: product,
          isFavorite: _favoriteProductIds.contains(product.id),
          onToggleFavorite: () => _toggleFavorite(product.id),
          onAddToCart: () => _addToCart(product),
          modelLoader: widget.modelLoader,
        ),
      ),
    );
  }

  void _changeCartQuantity(String productId, int delta) {
    setState(() {
      if (_cart.containsKey(productId)) {
        _cart[productId]!.quantity += delta;
        if (_cart[productId]!.quantity <= 0) {
          _cart.remove(productId);
        }
      }
    });
  }

  void _placeOrder(String name, String address) {
    if (_cart.isEmpty) return;
    final newOrder = OrderModel(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      items: _cart.values
          .map((e) => CartItem(product: e.product, quantity: e.quantity))
          .toList(),
      totalAmount: _cartTotalAmount,
      date: DateTime.now(),
      customerName: name.isEmpty ? 'عميل كويك ستور' : name,
      address: address.isEmpty ? 'القاهرة، مصر' : address,
    );

    setState(() {
      _ordersHistory.insert(0, newOrder);
      _cart.clear();
      _currentTabIndex = 3; // Switch to Orders tab
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('تم تأكيد الطلب بنجاح! 🎉'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'رقم الطلب: ${newOrder.id}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text('إجمالي المبلغ: \$${newOrder.totalAmount.toStringAsFixed(2)}'),
            Text('الاسم: ${newOrder.customerName}'),
            Text('العنوان: ${newOrder.address}'),
            const SizedBox(height: 10),
            const Text(
              'شكراً لتسوقك معنا! يمكنك متابعة طلبك من تبويب "طلباتي".',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            key: const Key('btn_order_success_ok'),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.storefront,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'QuickStore',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            ),
          ],
        ),
        actions: [
          // Cart Icon with Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                key: const Key('btn_appbar_cart'),
                tooltip: 'Shopping Cart',
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: () => setState(() => _currentTabIndex = 2),
              ),
              if (_cartItemCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_cartItemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          _buildProductsTab(),
          _buildFavoritesTab(),
          _buildCartTab(),
          _buildOrdersTab(),
        ],
      ),
      bottomNavigationBar: ClipRect(
        child: NavigationBar(
          selectedIndex: _currentTabIndex,
          onDestinationSelected: (idx) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            setState(() => _currentTabIndex = idx);
          },
          destinations: [
            const NavigationDestination(
              key: Key('nav_home'),
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              key: const Key('nav_favorites'),
              icon: Badge(
                isLabelVisible: _favoriteProductIds.isNotEmpty,
                label: Text('${_favoriteProductIds.length}'),
                child: const Icon(Icons.favorite_border),
              ),
              selectedIcon: const Icon(Icons.favorite),
              label: 'المفضلة',
            ),
            NavigationDestination(
              key: const Key('nav_cart'),
              icon: Badge(
                isLabelVisible: _cartItemCount > 0,
                label: Text('$_cartItemCount'),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              selectedIcon: const Icon(Icons.shopping_cart),
              label: 'السلة',
            ),
            NavigationDestination(
              key: const Key('nav_orders'),
              icon: Badge(
                isLabelVisible: _ordersHistory.isNotEmpty,
                label: Text('${_ordersHistory.length}'),
                child: const Icon(Icons.receipt_long_outlined),
              ),
              selectedIcon: const Icon(Icons.receipt_long),
              label: 'طلباتي',
            ),
          ],
        ),
      ),
    );
  }

  // TAB 1: Products Browsing
  Widget _buildProductsTab() {
    return Column(
      children: [
        // Search & Filter Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                key: const Key('input_search_products'),
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ابحث عن منتج أو فئة...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 10),
              // Category Filter Chips
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat;
                    return ChoiceChip(
                      key: Key('chip_category_$cat'),
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                      backgroundColor: const Color(0xFFF1F5F9),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onSelected: (selected) {
                        setState(() => _selectedCategory = cat);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Product Grid
        Expanded(
          child: _filteredProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'لا توجد منتجات تطابق "$_searchQuery"',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  key: const Key('grid_products'),
                  padding: const EdgeInsets.all(14),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    final isFav = _favoriteProductIds.contains(product.id);
                    return ProductCard(
                      product: product,
                      isFavorite: isFav,
                      onOpenDetails: () => _openProductDetails(product),
                      onToggleFavorite: () => _toggleFavorite(product.id),
                      onAddToCart: () => _addToCart(product),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // TAB 2: Favorites
  Widget _buildFavoritesTab() {
    final favoriteProducts = _allProducts
        .where((p) => _favoriteProductIds.contains(p.id))
        .toList();
    if (favoriteProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'قائمة المفضلة فارغة حالياً',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _currentTabIndex = 0),
              child: const Text('تصفح المنتجات الآن'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: favoriteProducts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = favoriteProducts[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: SizedBox.square(
              dimension: 48,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ProductPhoto(product: product),
              ),
            ),
            title: Text(
              product.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              '\$${product.price.toStringAsFixed(2)} • ${product.category}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Add to cart',
                  icon: const Icon(Icons.add_shopping_cart, color: Colors.blue),
                  onPressed: () => _addToCart(product),
                ),
                IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _toggleFavorite(product.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // TAB 3: Cart & Checkout
  Widget _buildCartTab() {
    if (_cart.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'سلة التسوق فارغة',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              key: const Key('btn_empty_cart_shop_now'),
              onPressed: () => setState(() => _currentTabIndex = 0),
              child: const Text('ابدأ التسوق الآن'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            key: const Key('list_cart_items'),
            padding: const EdgeInsets.all(16),
            itemCount: _cart.values.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = _cart.values.elementAt(index);
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      SizedBox.square(
                        dimension: 48,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ProductPhoto(product: item.product),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${item.product.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            key: Key('btn_cart_dec_${item.product.id}'),
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              size: 20,
                            ),
                            onPressed: () =>
                                _changeCartQuantity(item.product.id, -1),
                          ),
                          Text(
                            '${item.quantity}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          IconButton(
                            key: Key('btn_cart_inc_${item.product.id}'),
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 20,
                            ),
                            onPressed: () =>
                                _changeCartQuantity(item.product.id, 1),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Cart Summary & Checkout Bottom Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'الإجمالي الكلي:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${_cartTotalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  key: const Key('btn_checkout_open'),
                  onPressed: () => _showCheckoutBottomSheet(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'إتمام الطلب (Checkout) 🛍️',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  void _showCheckoutBottomSheet() {
    final nameCtrl = TextEditingController(text: 'محمد علي');
    final addressCtrl = TextEditingController(text: 'مدينة نصر، القاهرة');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'بيانات الشحن والدفع 📦',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('input_checkout_name'),
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'اسم المستلم',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('input_checkout_address'),
              controller: addressCtrl,
              decoration: const InputDecoration(
                labelText: 'عنوان التوصيل',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('المبلغ المطلوب سداده:'),
                  Text(
                    '\$${_cartTotalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                key: const Key('btn_confirm_place_order'),
                onPressed: () {
                  Navigator.pop(ctx);
                  _placeOrder(nameCtrl.text, addressCtrl.text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'تأكيد وشراء الآن ✅',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 4: Orders History
  Widget _buildOrdersTab() {
    if (_ordersHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'لم تقم بإجراء أي طلبات بعد',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => setState(() => _currentTabIndex = 0),
              child: const Text('تسوق الآن'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _ordersHistory.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = _ordersHistory[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.id,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'قيد التجهيز 🚚',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'المستلم: ${order.customerName} • ${order.address}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const Divider(height: 16),
                Column(
                  children: order.items
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${item.product.title} (x${item.quantity})',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                '\$${(item.product.price * item.quantity).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'الإجمالي:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${order.totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
