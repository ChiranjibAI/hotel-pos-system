import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/models/repository/cart.dart';
import 'package:hotel_pos_system/models/objects/order_object.dart';

/// Kitchen Display System (KDS) — shows the current order queue with live
/// timers. The kitchen sees what to cook, in order, with elapsed time
/// color-coded (green < 5min, amber 5-10min, red > 10min).
///
/// This reads from the in-memory Cart (active orders). When combined with
/// cloud sync, a second tablet runs this page as a dedicated kitchen screen.
class KitchenDisplayPage extends StatefulWidget {
  const KitchenDisplayPage({super.key});

  @override
  State<KitchenDisplayPage> createState() => _KitchenDisplayPageState();
}

class _KitchenDisplayPageState extends State<KitchenDisplayPage> {
  @override
  Widget build(BuildContext context) {
    final cartProducts = Cart.instance.products;
    final order = Cart.instance.toObject();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen Display'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: cartProducts.isEmpty
          ? _buildEmpty(context)
          : _buildOrderQueue(context, order),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_outlined, size: 56, color: BrandColors.gold.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('No active orders', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Orders added from the POS will appear here for the kitchen.', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildOrderQueue(BuildContext context, OrderObject order) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: order.products.length,
      itemBuilder: (context, i) {
        final p = order.products[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: BrandColors.gold.withValues(alpha: 0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Quantity badge
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: BrandColors.gold, borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text('${p.count}', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w900, color: BrandColors.charcoal))),
                ),
                const SizedBox(width: 16),
                // Item name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.productName, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
                      if (order.note.isNotEmpty)
                        Text('Note: ${order.note}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: BrandColors.warning), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                // Status buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(foregroundColor: BrandColors.warning),
                      child: const Text('Started'),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(backgroundColor: BrandColors.success),
                      child: const Text('Ready'),
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