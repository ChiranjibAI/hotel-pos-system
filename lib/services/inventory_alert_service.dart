import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hotel_pos_system/helpers/logger.dart';
import 'package:hotel_pos_system/models/repository/stock.dart';
import 'package:hotel_pos_system/models/stock/ingredient.dart';
import 'package:hotel_pos_system/services/cache.dart';

/// Inventory alert service — checks ingredient stock levels against
/// configurable thresholds and fires callbacks when items are low.
///
/// Uses a simple in-app notification (snackbar) rather than system push
/// notifications to avoid adding a platform-specific dependency. The
/// owner sees low-stock alerts when they open the app or after each
/// checkout (which deducts inventory).
class InventoryAlertService {
  static InventoryAlertService instance = InventoryAlertService();

  InventoryAlertService();

  static const _thresholdKey = 'inventory.lowStockThreshold';
  static const _enabledKey = 'inventory.alertsEnabled';

  /// Default threshold percentage — alert when currentAmount < 20% of totalAmount.
  static const double defaultThresholdPercent = 20.0;

  /// Whether alerts are enabled.
  bool get enabled => Cache.instance.get<bool>(_enabledKey) ?? true;

  /// The threshold percentage (0-100). Alert when stock drops below this % of total.
  double get thresholdPercent {
    final v = Cache.instance.get<int>(_thresholdKey);
    if (v == null) return defaultThresholdPercent;
    return v.toDouble();
  }

  Future<void> setEnabled(bool value) => Cache.instance.set<bool>(_enabledKey, value);
  Future<void> setThresholdPercent(double value) => Cache.instance.set<int>(_thresholdKey, value.round());

  /// Check all ingredients and return those that are below the threshold.
  List<Ingredient> getLowStockItems() {
    if (!enabled) return [];
    final threshold = thresholdPercent;
    final lowItems = <Ingredient>[];
    for (final ingredient in Stock.instance.items) {
      final total = ingredient.totalAmount ?? ingredient.lastAmount ?? ingredient.currentAmount;
      if (total <= 0) continue;
      final percent = (ingredient.currentAmount / total) * 100;
      if (percent < threshold) {
        lowItems.add(ingredient);
      }
    }
    return lowItems;
  }

  /// Check stock and fire [onAlert] for each low item. Call after checkout
  /// or on app startup.
  void checkAndAlert(void Function(List<Ingredient> lowItems) onAlert) {
    if (!enabled) return;
    final lowItems = getLowStockItems();
    if (lowItems.isNotEmpty) {
      Log.out('${lowItems.length} low-stock items', 'inventory_alert');
      onAlert(lowItems);
    }
  }
}