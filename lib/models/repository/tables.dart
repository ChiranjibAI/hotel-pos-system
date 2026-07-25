import 'package:flutter/widgets.dart';
import 'package:hotel_pos_system/models/repository.dart';
import 'package:hotel_pos_system/models/restaurant/table.dart';
import 'package:hotel_pos_system/services/storage.dart';

/// Repository of restaurant tables.
///
/// Tables are stored in the `tables` store (a new Stores enum value added in
/// the storage migration). The repository follows the same pattern as
/// [Printers] — a singleton [ChangeNotifier] with [RepositoryStorage].
class Tables extends ChangeNotifier with Repository<RestaurantTable>, RepositoryStorage<RestaurantTable> {
  static late Tables instance;

  @override
  final Stores storageStore = .tables;

  Tables() {
    instance = this;
  }

  @override
  final RepositoryStorageType repoType = .repoProperties;

  @override
  RestaurantTable buildItem(String id, Map<String, Object?> value) {
    return RestaurantTable.fromObject(TableObject.build({'id': id, ...value}));
  }

  /// Get all tables sorted by their grid position (top-to-bottom, left-to-right).
  List<RestaurantTable> get sorted => items.toList()..sort();

  /// Count of tables by status.
  Map<TableStatus, int> get statusCounts {
    final counts = <TableStatus, int>{};
    for (final t in items) {
      counts[t.tableStatus] = (counts[t.tableStatus] ?? 0) + 1;
    }
    return counts;
  }

  /// Find a table by name (case-insensitive).
  RestaurantTable? findByName(String name) {
    final lower = name.toLowerCase();
    for (final t in items) {
      if (t.name.toLowerCase() == lower) return t;
    }
    return null;
  }

  /// Set the status of a table and persist.
  Future<void> setStatus(RestaurantTable table, TableStatus status) async {
    final obj = TableObject(
      name: table.name,
      seats: table.seats,
      gridX: table.gridX,
      gridY: table.gridY,
      statusIndex: status.index,
      currentOrderId: status == TableStatus.available ? null : table.currentOrderId,
    );
    await table.update(obj);
    notifyItems();
  }

  /// Link an order to a table and mark it occupied.
  Future<void> linkOrder(RestaurantTable table, String orderId) async {
    final obj = TableObject(
      name: table.name,
      seats: table.seats,
      gridX: table.gridX,
      gridY: table.gridY,
      statusIndex: TableStatus.occupied.index,
      currentOrderId: orderId,
    );
    await table.update(obj);
    notifyItems();
  }

  /// Clear the order link and free the table (set to cleaning).
  Future<void> freeTable(RestaurantTable table) async {
    final obj = TableObject(
      name: table.name,
      seats: table.seats,
      gridX: table.gridX,
      gridY: table.gridY,
      statusIndex: TableStatus.cleaning.index,
    );
    await table.update(obj);
    notifyItems();
  }
}