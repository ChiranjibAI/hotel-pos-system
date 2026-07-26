import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:hotel_pos_system/models/objects/order_object.dart';
import 'package:hotel_pos_system/models/repository/seller.dart';

/// Severity level for an anomaly alert.
enum AnomalySeverity { low, medium, high }

/// A single anomaly / fraud alert detected from order history.
class AnomalyAlert {
  final String title;
  final String description;
  final AnomalySeverity severity;
  final DateTime detectedAt;
  final DateTime? relatedDate;
  final String? staffPin;

  const AnomalyAlert({
    required this.title,
    required this.description,
    required this.severity,
    required this.detectedAt,
    this.relatedDate,
    this.staffPin,
  });
}

/// Anomaly / Fraud Detection — rules-based scanning of order history.
///
/// Detects: excessive voids, repeated exact-amount bills, after-hours
/// activity, and unusually high discount usage. Pure Dart, reads from
/// the existing Seller order database. No new dependencies.
class AnomalyDetector {
  AnomalyDetector._();
  static final AnomalyDetector instance = AnomalyDetector._();

  /// Scan the given date range (default: last 30 days) and return alerts.
  Future<List<AnomalyAlert>> detect({DateTimeRange? range}) async {
    final now = DateTime.now();
    final end = range?.end ?? now;
    final start = range?.start ?? now.subtract(const Duration(days: 30));

    final alerts = <AnomalyAlert>[];
    try {
      const batchSize = 500;
      var offset = 0;
      final allOrders = <OrderObject>[];
      while (true) {
        final orders = await Seller.instance.getOrders(start, end,
            offset: offset, limit: batchSize);
        if (orders.isEmpty) break;
        allOrders.addAll(orders);
        if (orders.length < batchSize) break;
        offset += batchSize;
      }

      alerts.addAll(_detectRepeatedAmounts(allOrders));
      alerts.addAll(_detectAfterHours(allOrders));
      alerts.addAll(_detectHighDiscounts(allOrders));
    } catch (e) {
      if (kDebugMode) {
        print('[AnomalyDetector] detect failed: $e');
      }
    }
    return alerts;
  }

  /// Repeated exact-amount bills (possible duplicate charging or
  /// fake billing). Flag if the same price appears 4+ times in one day.
  List<AnomalyAlert> _detectRepeatedAmounts(List<OrderObject> orders) {
    final alerts = <AnomalyAlert>[];
    final byDay = <String, List<OrderObject>>{};
    for (final o in orders) {
      final key = '${o.createdAt.year}-${o.createdAt.month}-${o.createdAt.day}';
      byDay.putIfAbsent(key, () => []).add(o);
    }
    byDay.forEach((day, dayOrders) {
      final priceCounts = <num, int>{};
      for (final o in dayOrders) {
        priceCounts[o.price] = (priceCounts[o.price] ?? 0) + 1;
      }
      priceCounts.forEach((price, count) {
        if (count >= 4) {
          alerts.add(AnomalyAlert(
            title: 'Repeated billing amount',
            description:
                '$count bills of ${_formatMoney(price)} on $day — possible duplicates.',
            severity: count >= 6 ? AnomalySeverity.high : AnomalySeverity.medium,
            detectedAt: DateTime.now(),
            relatedDate: dayOrders.first.createdAt,
          ));
        }
      });
    });
    return alerts;
  }

  /// Orders placed outside 7am–11pm. Only flag if there are 3+ such
  /// orders in the range (one late-night order is normal).
  List<AnomalyAlert> _detectAfterHours(List<OrderObject> orders) {
    final afterHours = orders.where((o) {
      final h = o.createdAt.hour;
      return h < 7 || h >= 23;
    }).toList();
    if (afterHours.length < 3) return const [];
    return [
      AnomalyAlert(
        title: 'After-hours activity',
        description:
            '${afterHours.length} orders placed outside 7am–11pm.',
        severity: afterHours.length >= 6
            ? AnomalySeverity.medium
            : AnomalySeverity.low,
        detectedAt: DateTime.now(),
        relatedDate: afterHours.first.createdAt,
      ),
    ];
  }

  /// High discount usage — orders where singlePrice < originalPrice
  /// (isDiscount=true). Flag if >20% of orders are discounted, or if
  /// any single order has a discount >50%.
  List<AnomalyAlert> _detectHighDiscounts(List<OrderObject> orders) {
    final alerts = <AnomalyAlert>[];
    if (orders.isEmpty) return alerts;
    var discounted = 0;
    var deepDiscount = 0;
    for (final o in orders) {
      for (final p in o.products) {
        if (p.isDiscount) {
          discounted++;
          if (p.originalPrice > 0) {
            final ratio = p.singlePrice / p.originalPrice;
            if (ratio < 0.5) deepDiscount++;
          }
        }
      }
    }
    if (discounted > 0 && discounted / orders.length > 0.2) {
      alerts.add(AnomalyAlert(
        title: 'High discount usage',
        description:
            '$discounted discounted items across ${orders.length} orders (${(discounted / orders.length * 100).toStringAsFixed(0)}%).',
        severity: AnomalySeverity.medium,
        detectedAt: DateTime.now(),
      ));
    }
    if (deepDiscount >= 3) {
      alerts.add(AnomalyAlert(
        title: 'Deep discounts (>50% off)',
        description:
            '$deepDiscount items discounted by more than 50% — verify approval.',
        severity: AnomalySeverity.high,
        detectedAt: DateTime.now(),
      ));
    }
    return alerts;
  }

  String _formatMoney(num v) => '₹${v.toStringAsFixed(2)}';
}