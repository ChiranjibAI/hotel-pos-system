import 'package:hotel_pos_system/models/model.dart';
import 'package:hotel_pos_system/models/model_object.dart';
import 'package:hotel_pos_system/models/repository.dart';
import 'package:hotel_pos_system/models/repository/tables.dart';
import 'package:hotel_pos_system/services/storage.dart';

/// Status of a restaurant table.
enum TableStatus { available, occupied, reserved, cleaning }

/// A restaurant dining table.
///
/// Stored under the `tables` store. Each table has a display name, seat
/// count, floor-plan position (x/y grid), and a current status. When an
/// order is checked out, the table can be linked to it via [currentOrderId].
///
/// Note: the field is called [tableStatus] (not `status`) to avoid clashing
/// with [Model.status] which tracks the model lifecycle (normal/staged).
class RestaurantTable extends Model<TableObject> with ModelStorage<TableObject> implements Comparable<RestaurantTable> {
  /// Number of seats.
  int seats;

  /// Grid position for the floor plan (0-based, 0 = top-left).
  int gridX;
  int gridY;

  /// Current status of the table (available/occupied/reserved/cleaning).
  TableStatus tableStatus;

  /// The active order id associated with this table, if any.
  String? currentOrderId;

  @override
  final Stores storageStore = Stores.tables;

  @override
  Repository<RestaurantTable> get repository => Tables.instance;

  RestaurantTable({
    super.id,
    super.status = ModelStatus.normal,
    required String name,
    this.seats = 4,
    this.gridX = 0,
    this.gridY = 0,
    this.tableStatus = TableStatus.available,
    this.currentOrderId,
  }) : super(name: name);

  factory RestaurantTable.fromObject(TableObject object) {
    return RestaurantTable(
      id: object.id,
      name: object.name,
      seats: object.seats,
      gridX: object.gridX,
      gridY: object.gridY,
      tableStatus: TableStatus.values[object.statusIndex],
      currentOrderId: object.currentOrderId,
    );
  }

  @override
  TableObject toObject() {
    return TableObject(
      id: id,
      name: name,
      seats: seats,
      gridX: gridX,
      gridY: gridY,
      statusIndex: tableStatus.index,
      currentOrderId: currentOrderId,
    );
  }

  @override
  int compareTo(RestaurantTable other) {
    final r = gridY.compareTo(other.gridY);
    return r != 0 ? r : gridX.compareTo(other.gridX);
  }

  @override
  String get logName => 'table.$name';
}

class TableObject extends ModelObject<RestaurantTable> {
  final String? id;
  final String name;
  final int seats;
  final int gridX;
  final int gridY;
  final int statusIndex;
  final String? currentOrderId;

  const TableObject({
    this.id,
    required this.name,
    this.seats = 4,
    this.gridX = 0,
    this.gridY = 0,
    this.statusIndex = 0,
    this.currentOrderId,
  });

  @override
  Map<String, Object> toMap() {
    return {
      'name': name,
      'seats': seats,
      'gridX': gridX,
      'gridY': gridY,
      'statusIndex': statusIndex,
      'currentOrderId': currentOrderId ?? '',
    };
  }

  @override
  Map<String, Object> diff(RestaurantTable model) {
    final result = <String, Object>{};
    final prefix = model.prefix;

    if (name != model.name) {
      model.name = name;
      result['$prefix.name'] = name;
    }
    if (seats != model.seats) {
      model.seats = seats;
      result['$prefix.seats'] = seats;
    }
    if (gridX != model.gridX) {
      model.gridX = gridX;
      result['$prefix.gridX'] = gridX;
    }
    if (gridY != model.gridY) {
      model.gridY = gridY;
      result['$prefix.gridY'] = gridY;
    }
    if (statusIndex != model.tableStatus.index) {
      model.tableStatus = TableStatus.values[statusIndex];
      result['$prefix.statusIndex'] = statusIndex;
    }
    final orderIdVal = currentOrderId ?? '';
    final modelOrderId = model.currentOrderId ?? '';
    if (orderIdVal != modelOrderId) {
      model.currentOrderId = orderIdVal.isEmpty ? null : orderIdVal;
      result['$prefix.currentOrderId'] = orderIdVal;
    }

    return result;
  }

  factory TableObject.build(Map<String, Object?> data) {
    final orderId = data['currentOrderId'] as String?;
    return TableObject(
      id: data['id'] as String?,
      name: data['name'] as String? ?? '',
      seats: data['seats'] as int? ?? 4,
      gridX: data['gridX'] as int? ?? 0,
      gridY: data['gridY'] as int? ?? 0,
      statusIndex: data['statusIndex'] as int? ?? 0,
      currentOrderId: (orderId == null || orderId.isEmpty) ? null : orderId,
    );
  }
}