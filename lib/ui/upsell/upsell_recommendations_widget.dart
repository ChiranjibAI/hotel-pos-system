import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/models/menu/product.dart';
import 'package:hotel_pos_system/models/repository/cart.dart';
import 'package:hotel_pos_system/models/repository/menu.dart';
import 'package:hotel_pos_system/services/upsell_engine.dart';

/// A compact horizontal strip that shows "Customers also ordered" chips
/// below the cart. Tapping a chip adds that product to the cart.
///
/// Shows nothing if there are no recommendations (e.g. empty cart, no
/// order history yet). Designed to be embedded inside the order page.
class UpsellRecommendationsWidget extends StatefulWidget {
  const UpsellRecommendationsWidget({super.key});

  @override
  State<UpsellRecommendationsWidget> createState() =>
      _UpsellRecommendationsWidgetState();
}

class _UpsellRecommendationsWidgetState
    extends State<UpsellRecommendationsWidget> {
  @override
  void initState() {
    super.initState();
    // Kick off a rebuild of the co-occurrence matrix in the background.
    UpsellEngine.instance.rebuildIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Cart.instance,
      builder: (context, _) {
        final cartIds = Cart.instance.products
            .map((p) => p.product.id)
            .toList();
        final recs = UpsellEngine.instance.recommendForCart(cartIds);
        if (recs.isEmpty) return const SizedBox.shrink();

        // Resolve product objects, skip any that no longer exist.
        final products = <Product>[];
        for (final id in recs) {
          final p = Menu.instance.getProduct(id);
          if (p != null) products.add(p);
        }
        if (products.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 14, color: BrandColors.gold),
                  const SizedBox(width: 6),
                  Text(
                    'Customers also ordered',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: BrandColors.gold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: products.map((p) => _buildChip(p)).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip(Product product) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(
          product.name,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        avatar: Icon(Icons.add, size: 14, color: BrandColors.gold),
        backgroundColor: BrandColors.gold.withValues(alpha: 0.08),
        side: BorderSide(color: BrandColors.gold.withValues(alpha: 0.3)),
        onPressed: () {
          Cart.instance.add(product);
        },
      ),
    );
  }
}