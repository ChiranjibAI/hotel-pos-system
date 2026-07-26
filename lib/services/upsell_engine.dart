import 'package:flutter/foundation.dart';
import 'package:hotel_pos_system/models/objects/order_object.dart';
import 'package:hotel_pos_system/models/repository/seller.dart';

/// Smart Upsell Engine — collaborative filtering over past orders.
///
/// For the items in the current cart, finds what other orders also
/// contained those items and surfaces the most frequently co-occurring
/// items that are not already in the cart. Pure Dart, no external deps.
///
/// The co-occurrence matrix is cached in memory and rebuilt on demand
/// (once per app session or when invalidated). All scoring is weighted
/// by recency so recent order trends matter more than stale ones.
class UpsellEngine extends ChangeNotifier {
  UpsellEngine._();
  static final UpsellEngine instance = UpsellEngine._();

  bool _built = false;
  DateTime? _builtAt;

  /// productId -> {otherProductId: weightedCoOccurrenceScore}
  final Map<String, Map<String, double>> _coOccurrence = {};

  /// How many days of order history to consider.
  static const _historyDays = 90;

  /// Whether the engine has data ready to serve recommendations.
  bool get isReady => _built && _coOccurrence.isNotEmpty;

  /// Rebuild the co-occurrence matrix from the last [_historyDays] of orders.
  Future<void> rebuildIfNeeded({bool force = false}) async {
    if (_built && !force && _builtAt != null &&
        DateTime.now().difference(_builtAt!) < const Duration(hours: 6)) {
      return;
    }
    await _build();
  }

  Future<void> _build() async {
    _coOccurrence.clear();
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: _historyDays));
    try {
      // Fetch orders in batches to avoid loading everything at once.
      const batchSize = 200;
      var offset = 0;
      while (true) {
        final orders = await Seller.instance.getOrders(start, now,
            offset: offset, limit: batchSize);
        if (orders.isEmpty) break;
        for (final order in orders) {
          _accumulateOrder(order, now);
               }
        if (orders.length < batchSize) break;
        offset += batchSize;
      }
    } catch (e) {
      // If the DB is unavailable or empty, leave the matrix empty.
      if (kDebugMode) {
        print('[UpsellEngine] build failed: $e');
      }
    }
    _built = true;
    _builtAt = DateTime.now();
    notifyListeners();
  }

  void _accumulateOrder(OrderObject order, DateTime now) {
    final productIds = order.products
        .map((p) => p.productId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (productIds.length < 2) return;

    // Recency weight: orders in the last 14 days count fully, older orders
    // decay linearly to 0.3 at 90 days.
    final ageDays = now.difference(order.createdAt).inDays;
    final recency = ageDays < 14
        ? 1.0
        : (1.0 - (ageDays - 14) / 76).clamp(0.3, 1.0);

    for (var i = 0; i < productIds.length; i++) {
      for (var j = 0; j < productIds.length; j++) {
        if (i == j) continue;
        final a = productIds[i];
        final b = productIds[j];
        _coOccurrence.putIfAbsent(a, () => {});
        _coOccurrence[a]![b] = (_coOccurrence[a]![b] ?? 0) + recency;
      }
    }
  }

  /// Recommend up to [limit] product IDs that co-occur with the current
  /// cart items but are not already in the cart.
  List<String> recommendForCart(List<String> cartProductIds, {int limit = 3}) {
    if (!_built || _coOccurrence.isEmpty || cartProductIds.isEmpty) {
      return const [];
    }
    final cartSet = cartProductIds.toSet();
    final scores = <String, double>{};
    for (final id in cartProductIds) {
      final neighbors = _coOccurrence[id];
      if (neighbors == null) continue;
      neighbors.forEach((otherId, score) {
        if (cartSet.contains(otherId)) return;
        scores[otherId] = (scores[otherId] ?? 0) + score;
      });
    }
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// Invalidate the cache so the next call rebuilds.
  void invalidate() {
    _built = false;
    _builtAt = null;
  }
}