import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/components/style/empty_body.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/models/menu/product.dart';
import 'package:hotel_pos_system/models/repository/menu.dart';
import 'package:hotel_pos_system/models/repository/seller.dart';

/// Menu Engineering report — classifies every dish into 4 quadrants:
///
/// - STARS: high profit + popular (keep, promote)
/// - PLOWHORSES: low profit + popular (reprice up)
/// - DOGS: low profit + unpopular (remove)
/// - PUZZLES: high profit + unpopular (reposition, rebrand)
///
/// Based on the classic menu engineering matrix (Kasavana & Smith, 1982).
class MenuEngineeringPage extends StatefulWidget {
  const MenuEngineeringPage({super.key});

  @override
  State<MenuEngineeringPage> createState() => _MenuEngineeringPageState();
}

class _MenuEngineeringPageState extends State<MenuEngineeringPage> {
  List<_MenuClassification> _classifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final menu = Menu.instance;
    if (menu.isEmpty) { setState(() => _loading = false); return; }

    final products = menu.products.toList();
    if (products.isEmpty) { setState(() => _loading = false); return; }

    // Get item-level sales counts for popularity
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));
    Map<String, int> salesCounts = {};
    try {
      final perItem = await Seller.instance.getMetricsByItems(start, now, type: OrderMetricType.count, target: OrderMetricTarget.product);
      for (final item in perItem) {
        salesCounts[item.name] = item.value.toInt();
      }
    } catch (_) {}

    // Calculate profit per product
    final profits = <String, num>{};
    for (final p in products) {
      final cost = _calculateCost(p);
      profits[p.name] = p.price - cost;
    }

    // Calculate medians
    final profitValues = profits.values.toList()..sort();
    final countValues = salesCounts.values.toList()..sort();
    final profitMedian = profitValues.isEmpty ? 0.0 : profitValues[profitValues.length ~/ 2].toDouble();
    final countMedian = countValues.isEmpty ? 0.0 : countValues[countValues.length ~/ 2].toDouble();

    // Classify
    final results = <_MenuClassification>[];
    for (final p in products) {
      final profit = (profits[p.name] ?? 0).toDouble();
      final count = (salesCounts[p.name] ?? 0).toDouble();
      final isHighProfit = profit >= profitMedian;
      final isHighPopularity = count >= countMedian;

      _MenuCategory category;
      if (isHighProfit && isHighPopularity) {
        category = _MenuCategory.star;
      } else if (!isHighProfit && isHighPopularity) {
        category = _MenuCategory.plowhorse;
      } else if (!isHighProfit && !isHighPopularity) {
        category = _MenuCategory.dog;
      } else {
        category = _MenuCategory.puzzle;
      }

      results.add(_MenuClassification(
        product: p, profit: profit, orderCount: count.toInt(), category: category,
      ));
    }

    // Sort: stars first, then puzzles, plowhorses, dogs
    results.sort((a, b) => a.category.index.compareTo(b.category.index));

    setState(() { _classifications = results; _loading = false; });
  }

  double _calculateCost(Product product) {
    var cost = 0.0;
    for (final pi in product.items) {
      final ingredient = pi.ingredient;
      if (ingredient.restockPrice != null && ingredient.restockQuantity > 0) {
        cost += pi.amount * (ingredient.restockPrice! / ingredient.restockQuantity);
      }
    }
    return cost > 0 ? cost : product.cost.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu Engineering')),
      body: _loading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : _classifications.isEmpty
              ? const EmptyBody(title: 'No menu items', content: 'Add products with ingredients to analyze.', icon: Icons.analytics_outlined, onPressed: null)
              : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    // Legend
    final stars = _classifications.where((c) => c.category == _MenuCategory.star).length;
    final plowhorses = _classifications.where((c) => c.category == _MenuCategory.plowhorse).length;
    final dogs = _classifications.where((c) => c.category == _MenuCategory.dog).length;
    final puzzles = _classifications.where((c) => c.category == _MenuCategory.puzzle).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Legend row
        Row(
          children: [
            _LegendChip(label: 'Stars', count: stars, color: BrandColors.gold),
            _LegendChip(label: 'Plowhorses', count: plowhorses, color: BrandColors.success),
            _LegendChip(label: 'Puzzles', count: puzzles, color: BrandColors.warning),
            _LegendChip(label: 'Dogs', count: dogs, color: BrandColors.danger),
          ],
        ),
        const SizedBox(height: 16),
        ..._classifications.map((c) => _ClassificationCard(c: c)),
      ],
    );
  }
}

class _ClassificationCard extends StatelessWidget {
  final _MenuClassification c;
  const _ClassificationCard({required this.c});

  @override
  Widget build(BuildContext context) {
    final config = _categoryConfig(c.category);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: config.color.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: config.color, borderRadius: BorderRadius.circular(10)),
          child: Icon(config.icon, color: Colors.black87, size: 22),
        ),
        title: Text(c.product.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        subtitle: Text('Profit: \$${c.profit.toStringAsFixed(2)} • ${c.orderCount} orders', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: config.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Text(config.label, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: config.color)),
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _LegendChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
          child: Column(
            children: [
              Text('$count', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
              Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 9, color: color), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

enum _MenuCategory { star, plowhorse, puzzle, dog }

class _MenuClassification {
  final Product product;
  final double profit;
  final int orderCount;
  final _MenuCategory category;
  const _MenuClassification({required this.product, required this.profit, required this.orderCount, required this.category});
}

_CategoryConfig _categoryConfig(_MenuCategory c) => switch (c) {
  _MenuCategory.star => const _CategoryConfig(label: 'STAR', icon: Icons.star_rounded, color: BrandColors.gold, advice: 'Keep & promote'),
  _MenuCategory.plowhorse => const _CategoryConfig(label: 'PLOWHORSE', icon: Icons.agriculture_outlined, color: BrandColors.success, advice: 'Reprice up'),
  _MenuCategory.puzzle => const _CategoryConfig(label: 'PUZZLE', icon: Icons.extension_outlined, color: BrandColors.warning, advice: 'Reposition'),
  _MenuCategory.dog => const _CategoryConfig(label: 'DOG', icon: Icons.pets_outlined, color: BrandColors.danger, advice: 'Consider removing'),
};

class _CategoryConfig {
  final String label;
  final IconData icon;
  final Color color;
  final String advice;
  const _CategoryConfig({required this.label, required this.icon, required this.color, required this.advice});
}