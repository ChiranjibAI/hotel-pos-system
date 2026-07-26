import 'package:flutter/foundation.dart';
import 'package:hotel_pos_system/models/repository/customers.dart';

/// Churn risk tier.
enum ChurnTier { stable, atRisk, critical }

/// Churn risk assessment for a single customer.
class ChurnRisk {
  final String name;
  final String phone;
  final num totalSpent;
  final int orderCount;
  final double score; // 0.0 to 1.0
  final ChurnTier tier;

  const ChurnRisk({
    required this.name,
    required this.phone,
    required this.totalSpent,
    required this.orderCount,
    required this.score,
    required this.tier,
  });
}

/// Churn Prediction — flags loyalty customers at risk of churning.
///
/// Uses order count and total spend as proxies (without per-customer
/// last-visit timestamps). Customers with low order counts or
/// declining spend are flagged as higher risk. Pure Dart.
class ChurnPredictor {
  ChurnPredictor._();
  static final ChurnPredictor instance = ChurnPredictor._();

  /// Assess churn risk for all loyalty customers.
  List<ChurnRisk> predict() {
    try {
      final customers = Customers.instance.items;
      if (customers.isEmpty) return [];

      final risks = <ChurnRisk>[];
      for (final c in customers) {
        // Score: fewer orders + lower spend = higher churn risk.
        // Without last-visit data, we use order frequency as a proxy.
        // 0 orders = 0.9 (critical), 1-2 orders = 0.6, 3-5 = 0.3, 6+ = 0.1
        double score;
        if (c.orderCount == 0) {
          score = 0.9;
        } else if (c.orderCount <= 2) {
          score = 0.6;
        } else if (c.orderCount <= 5) {
          score = 0.3;
        } else {
          score = 0.1;
        }
        // Adjust by spend: very low spend increases risk slightly.
        if (c.totalSpent < 200 && c.orderCount > 0) score += 0.1;
        score = score.clamp(0.0, 1.0);

        risks.add(ChurnRisk(
          name: c.name,
          phone: c.phone,
          totalSpent: c.totalSpent,
          orderCount: c.orderCount,
          score: score,
          tier: score >= 0.7 ? ChurnTier.critical : (score >= 0.4 ? ChurnTier.atRisk : ChurnTier.stable),
        ));
      }
      risks.sort((a, b) => b.score.compareTo(a.score));
      return risks;
    } catch (e) {
      if (kDebugMode) print('[ChurnPredictor] predict failed: $e');
      return [];
    }
  }
}