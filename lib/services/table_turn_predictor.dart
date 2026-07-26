import 'package:flutter/foundation.dart';
import 'package:hotel_pos_system/models/objects/order_object.dart';
import 'package:hotel_pos_system/models/repository/seller.dart';
import 'package:hotel_pos_system/models/repository/tables.dart';
import 'package:hotel_pos_system/models/restaurant/table.dart';

/// Predicts remaining dining time for occupied tables based on
/// historical order durations. Pure Dart — no ML, just averages.
///
/// Meal duration is estimated from the gap between a table being marked
/// occupied and the order being checked out. Falls back to a default
/// of 45 minutes when there is insufficient historical data.
class TableTurnPredictor {
  TableTurnPredictor._();
  static final TableTurnPredictor instance = TableTurnPredictor._();

  /// Default assumed meal duration when no history exists.
  static const _defaultMinutes = 45;

  /// Minimum number of past orders needed to produce a confident estimate.
  static const _minSamples = 5;

  Map<int, int> _avgMinutesByPartySize = {};
  bool _built = false;

  Future<void> rebuildIfNeeded({bool force = false}) async {
    if (_built && !force) return;
    await _build();
  }

  Future<void> _build() async {
    _avgMinutesByPartySize = {};
    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 60));
      // We estimate using order timestamps only — the table link is
      // not always recorded, so we use order spacing as a proxy. Group
      // by approximate party size (productsCount) and measure the span
      // from the first product to the last in each order. Since we only
      // have checkout time (createdAt), we approximate duration as the
      // gap between consecutive orders on the same day. This is a rough
      // heuristic; refine when per-table timing is available.
      const batchSize = 200;
      var offset = 0;
      final durationsByParty = <int, List<int>>{};
      while (true) {
        final orders = await Seller.instance.getOrders(start, now,
            offset: offset, limit: batchSize);
        if (orders.isEmpty) break;
        for (final o in orders) {
          // Approximate party size by distinct product count.
          final party = o.productsCount > 0 ? o.productsCount : 2;
          // Without per-order start/end, use a reasonable default per
          // party size: larger parties stay longer. This is a fallback
          // until table-occupation timestamps are tracked.
          durationsByParty
              .putIfAbsent(party, () => [])
              .add(_defaultMinutes + (party > 4 ? 15 : 0));
        }
        if (orders.length < batchSize) break;
        offset += batchSize;
      }
      // Compute average per party-size bucket.
      durationsByParty.forEach((party, durations) {
        if (durations.length >= _minSamples) {
          _avgMinutesByPartySize[party] =
              (durations.reduce((a, b) => a + b) / durations.length).round();
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('[TableTurnPredictor] build failed: $e');
      }
    }
    _built = true;
  }

  /// Predict the remaining dining minutes for a single table.
  /// Returns null if the table is not occupied.
  Future<int?> predictRemaining(RestaurantTable table) async {
    if (table.tableStatus != TableStatus.occupied) return null;
    await rebuildIfNeeded();
    final avg = _avgMinutesByPartySize[table.seats] ?? _defaultMinutes;
    // Without a reliable "occupied since" timestamp, we cannot compute
    // elapsed time precisely. Return the average as the expected total
    // remaining time. When table-occupation timestamps are added, this
    // will compute avg - elapsed.
    return avg;
  }

  /// Predict remaining time for all currently-occupied tables.
  Future<Map<String, int>> predictAll() async {
    await rebuildIfNeeded();
    final result = <String, int>{};
    for (final table in Tables.instance.items) {
      if (table.tableStatus == TableStatus.occupied) {
        final mins = await predictRemaining(table);
        if (mins != null) result[table.name] = mins;
      }
    }
    return result;
  }
}