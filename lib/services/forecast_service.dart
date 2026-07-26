import 'package:flutter/foundation.dart';
import 'package:hotel_pos_system/models/repository/seller.dart';

/// Forecast result for a single day.
class ForecastResult {
  final DateTime date;
  final int predictedOrders;
  final num predictedRevenue;
  final double confidence; // 0.0 to 1.0

  const ForecastResult({
    required this.date,
    required this.predictedOrders,
    required this.predictedRevenue,
    required this.confidence,
  });
}

/// A line item in a suggested purchase order.
class PurchaseOrderLine {
  final String ingredientName;
  final num quantityNeeded;
  final num currentStock;
  final num shortfall;

  const PurchaseOrderLine({
    required this.ingredientName,
    required this.quantityNeeded,
    required this.currentStock,
    required this.shortfall,
  });
}

/// Demand Forecasting + Auto Purchase Orders.
///
/// Uses moving average + day-of-week seasonality from the last 30
/// days of order history to predict the next 7 days. Pure Dart —
/// no ML, just weighted averages. Confidence increases with more
/// historical data.
class ForecastService {
  ForecastService._();
  static final ForecastService instance = ForecastService._();

  /// Forecast the next 7 days based on historical order data.
  Future<List<ForecastResult>> forecast7Days() async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));
    try {
      final metrics = await Seller.instance.getMetricsInPeriod(
        start, now,
        types: [OrderMetricType.count, OrderMetricType.revenue],
        interval: MetricsIntervalType.day,
        ignoreEmpty: false,
      );
      if (metrics.isEmpty) return [];

      // Build a map: weekday (1=Mon) -> list of values
      final byWeekday = <int, List<OrderSummary>>{};
      for (final m in metrics) {
        byWeekday.putIfAbsent(m.at.weekday, () => []).add(m);
      }

      // Overall moving average
      final avgOrders = metrics.fold<double>(0, (a, m) => a + (m.values['count'] ?? 0)) / metrics.length;
      final avgRevenue = metrics.fold<double>(0, (a, m) => a + (m.values['revenue'] ?? 0)) / metrics.length;

      // Confidence: based on data volume. 30 days = 1.0, less = lower.
      final confidence = (metrics.length / 30).clamp(0.0, 1.0);

      final results = <ForecastResult>[];
      for (var i = 1; i <= 7; i++) {
        final date = DateTime(now.year, now.month, now.day).add(Duration(days: i));
        final weekdayData = byWeekday[date.weekday] ?? const [];
        if (weekdayData.isEmpty) {
          results.add(ForecastResult(
            date: date,
            predictedOrders: avgOrders.round(),
            predictedRevenue: avgRevenue,
            confidence: confidence * 0.7,
          ));
        } else {
          // Day-of-week average
          final dayAvgOrders = weekdayData.fold<double>(0, (a, m) => a + (m.values['count'] ?? 0)) / weekdayData.length;
          final dayAvgRevenue = weekdayData.fold<double>(0, (a, m) => a + (m.values['revenue'] ?? 0)) / weekdayData.length;
          // Blend: 70% day-of-week, 30% overall average
          final blendedOrders = dayAvgOrders * 0.7 + avgOrders * 0.3;
          final blendedRevenue = dayAvgRevenue * 0.7 + avgRevenue * 0.3;
          results.add(ForecastResult(
            date: date,
            predictedOrders: blendedOrders.round(),
            predictedRevenue: blendedRevenue,
            confidence: confidence,
          ));
        }
      }
      return results;
    } catch (e) {
      if (kDebugMode) print('[ForecastService] forecast failed: $e');
      return [];
    }
  }

  /// Generate a purchase order based on forecast vs current stock.
  /// Returns lines where there is a shortfall (needed > available).
  Future<List<PurchaseOrderLine>> generatePO() async {
    // Without recipe-costing-to-ingredient mapping in a simple form,
    // we return an empty list with a note. This is a hook for when
    // recipe costing data is fully wired.
    // TODO: integrate with Stock.instance and recipe costing when available.
    return [];
  }
}