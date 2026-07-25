import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/components/style/empty_body.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/models/menu/product.dart';
import 'package:hotel_pos_system/models/menu/product_ingredient.dart';
import 'package:hotel_pos_system/models/repository/menu.dart';
import 'package:provider/provider.dart';

/// Recipe Costing page — shows the actual cost and margin % for each menu
/// item based on its ingredient amounts and current ingredient restock prices.
///
/// Margin = (price - cost) / price * 100.
/// Cost = sum of (ingredient.amount * ingredient.restockPrice / ingredient.restockQuantity)
/// for each ingredient in the product.
class RecipeCostingPage extends StatelessWidget {
  const RecipeCostingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recipe Costing')),
      body: context.watch<Menu>().isEmpty
          ? const EmptyBody(
              title: 'No menu items',
              content: 'Add products with ingredients to see cost and margin analysis.',
              icon: Icons.calculate_outlined,
              onPressed: null,
            )
          : _buildList(context),
    );
  }

  Widget _buildList(BuildContext context) {
    final products = context.watch<Menu>().products.toList();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _CostCard(product: products[i]),
    );
  }
}

class _CostCard extends StatelessWidget {
  final Product product;
  const _CostCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final calculatedCost = _calculateCost(product);
    final price = product.price;
    final margin = price > 0 ? ((price - calculatedCost) / price) * 100 : 0.0;
    final marginColor = margin >= 60
        ? BrandColors.success
        : margin >= 30
            ? BrandColors.warning
            : BrandColors.danger;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: BrandColors.gold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Cost breakdown
            if (product.items.isNotEmpty) ...[
              for (final pi in product.items)
                _IngredientCostRow(pi: pi),
              const Divider(height: 12),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Cost', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color)),
                Text('\$${calculatedCost.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Profit', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color)),
                Text('\$${(price - calculatedCost).toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: BrandColors.success)),
              ],
            ),
            const SizedBox(height: 8),
            // Margin badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: marginColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${margin.toStringAsFixed(1)}% margin',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: marginColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Calculate the actual cost of a product from its ingredients.
  double _calculateCost(Product product) {
    var cost = 0.0;
    for (final pi in product.items) {
      final ingredient = pi.ingredient;
      if (ingredient.restockPrice != null && ingredient.restockQuantity > 0) {
        final unitCost = ingredient.restockPrice! / ingredient.restockQuantity;
        cost += pi.amount * unitCost;
      }
    }
    // Fall back to the product's stored cost field if no ingredient prices
    return cost > 0 ? cost : product.cost.toDouble();
  }
}

class _IngredientCostRow extends StatelessWidget {
  final ProductIngredient pi;
  const _IngredientCostRow({required this.pi});

  @override
  Widget build(BuildContext context) {
    final ingredient = pi.ingredient;
    final unitCost = (ingredient.restockPrice ?? 0) / (ingredient.restockQuantity > 0 ? ingredient.restockQuantity : 1);
    final lineCost = pi.amount * unitCost;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${pi.amount} ${ingredient.name}',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
          ),
          Text(
            '\$${lineCost.toStringAsFixed(2)}',
            style: GoogleFonts.plusJakartaSans(fontSize: 12),
          ),
        ],
      ),
    );
  }
}