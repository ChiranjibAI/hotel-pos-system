import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/components/style/empty_body.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/helpers/logger.dart';
import 'package:hotel_pos_system/models/repository/cart.dart';
import 'package:hotel_pos_system/models/menu/product.dart';
import 'package:hotel_pos_system/models/repository/menu.dart';

/// Zomato/Swiggy Order Import page — lets the owner manually enter aggregator
/// orders (Zomato, Swiggy, etc.) into the POS so all sales are tracked in one
/// place.
///
/// The owner selects items from the menu, enters the aggregator order ID, and
/// the order is added to the cart with an "aggregator" tag. This is a manual
/// import — full API integration with Zomato/Swiggy requires their partner API
/// credentials and is a future enhancement.
class AggregatorImportPage extends StatefulWidget {
  const AggregatorImportPage({super.key});

  @override
  State<AggregatorImportPage> createState() => _AggregatorImportPageState();
}

class _AggregatorImportPageState extends State<AggregatorImportPage> {
  String _selectedAggregator = 'Zomato';
  final _orderIdCtrl = TextEditingController();
  final List<Product> _selectedProducts = [];
  final List<int> _quantities = [];

  static const _aggregators = ['Zomato', 'Swiggy', 'Blinkit', 'Zepto', 'Magicpin'];

  @override
  void dispose() {
    _orderIdCtrl.dispose();
    super.dispose();
  }

  void _toggleProduct(Product product) {
    setState(() {
      final idx = _selectedProducts.indexOf(product);
      if (idx >= 0) {
        _selectedProducts.removeAt(idx);
        _quantities.removeAt(idx);
      } else {
        _selectedProducts.add(product);
        _quantities.add(1);
      }
    });
  }

  void _changeQty(int index, int delta) {
    setState(() {
      final newQty = _quantities[index] + delta;
      if (newQty <= 0) {
        _selectedProducts.removeAt(index);
        _quantities.removeAt(index);
      } else {
        _quantities[index] = newQty;
      }
    });
  }

  Future<void> _importOrder() async {
    if (_selectedProducts.isEmpty || _orderIdCtrl.text.trim().isEmpty) return;

    // Add each product to the cart
    for (var i = 0; i < _selectedProducts.length; i++) {
      for (var q = 0; q < _quantities[i]; q++) {
        Cart.instance.add(_selectedProducts[i]);
      }
    }

    Log.ger('aggregator_import', {
      'source': _selectedAggregator,
      'orderId': _orderIdCtrl.text.trim(),
      'items': _selectedProducts.length,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_selectedAggregator order ${_orderIdCtrl.text} imported — ${_selectedProducts.length} items added to cart'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: BrandColors.success,
        ),
      );
      // Reset
      setState(() {
        _selectedProducts.clear();
        _quantities.clear();
        _orderIdCtrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = Menu.instance.products.toList();
    final total = _selectedProducts.asMap().entries.fold<num>(0, (sum, e) {
      final idx = e.key;
      return sum + _selectedProducts[idx].price * _quantities[idx];
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Aggregator Import')),
      body: Column(
        children: [
          // Aggregator + order ID
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                // Aggregator dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedAggregator,
                    underline: const SizedBox.shrink(),
                    items: _aggregators.map((a) => DropdownMenuItem(value: a, child: Text(a, style: GoogleFonts.plusJakartaSans()))).toList(),
                    onChanged: (v) => setState(() => _selectedAggregator = v!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _orderIdCtrl,
                    decoration: const InputDecoration(hintText: 'Aggregator Order ID', prefixIcon: Icon(Icons.receipt_outlined), isDense: true),
                  ),
                ),
              ],
            ),
          ),
          // Selected items summary
          if (_selectedProducts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text('${_selectedProducts.length} items', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('Total: \$${total.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: BrandColors.gold)),
                ],
              ),
            ),
          // Product list
          Expanded(
            child: products.isEmpty
                ? const EmptyBody(title: 'No menu items', content: 'Add products to your menu first.', icon: Icons.restaurant_menu_outlined, onPressed: null)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: products.length,
                    itemBuilder: (context, i) {
                      final product = products[i];
                      final selectedIdx = _selectedProducts.indexOf(product);
                      final selected = selectedIdx >= 0;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          leading: selected
                              ? Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(color: BrandColors.gold, borderRadius: BorderRadius.circular(10)),
                                  child: Center(child: Text('${_quantities[selectedIdx]}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: BrandColors.charcoal))),
                                )
                              : CircleAvatar(backgroundColor: BrandColors.gold.withValues(alpha: 0.12), child: Text(product.name.isNotEmpty ? product.name[0].toUpperCase() : '?', style: GoogleFonts.plusJakartaSans(color: BrandColors.gold))),
                          title: Text(product.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                          subtitle: Text('\$${product.price.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                          trailing: selected
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _changeQty(selectedIdx, -1)),
                                    IconButton(icon: const Icon(Icons.add_circle_outline, color: BrandColors.gold), onPressed: () => _changeQty(selectedIdx, 1)),
                                  ],
                                )
                              : IconButton(icon: const Icon(Icons.add_circle_outline, color: BrandColors.gold), onPressed: () => _toggleProduct(product)),
                          onTap: () => _toggleProduct(product),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selectedProducts.isEmpty ? null : _importOrder,
        icon: const Icon(Icons.download_outlined),
        label: const Text('Import to Cart'),
        backgroundColor: BrandColors.gold,
        foregroundColor: BrandColors.charcoal,
      ),
    );
  }
}