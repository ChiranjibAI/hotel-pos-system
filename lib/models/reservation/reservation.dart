import 'package:flutter/widgets.dart';
import 'package:hotel_pos_system/models/model.dart';
import 'package:hotel_pos_system/models/model_object.dart';
import 'package:hotel_pos_system/models/repository.dart';
import 'package:hotel_pos_system/services/storage.dart';

/// Forward-declared repository setter — breaks the circular dependency.
Repository<Reservation>? _reservationsRepo;
set reservationsRepository(Repository<Reservation> r) => _reservationsRepo = r;

/// Reservation status.
enum ReservationStatus { pending, confirmed, seated, cancelled, noShow }

/// A restaurant reservation — customer name, phone, date/time, party size,
/// and status. Stored under the `reservations` store.
///
/// Note: the field is [reservationStatus] (not `status`) to avoid clashing
/// with [Model.status] which tracks the model lifecycle (normal/staged).
class Reservation extends Model<ReservationObject> with ModelStorage<ReservationObject> implements Comparable<Reservation> {
  String customerPhone;
  DateTime dateTime;
  int partySize;
  ReservationStatus reservationStatus;
  String? tableId;
  String? notes;

  @override
  final Stores storageStore = Stores.reservations;

  @override
  Repository<Reservation> get repository => _reservationsRepo!;

  Reservation({
    super.id,
    super.status = ModelStatus.normal,
    required String name,
    required this.customerPhone,
    required this.dateTime,
    this.partySize = 2,
    this.reservationStatus = ReservationStatus.pending,
    this.tableId,
    this.notes,
  }) : super(name: name);

  factory Reservation.fromObject(ReservationObject object) {
    return Reservation(
      id: object.id,
      name: object.customerName,
      customerPhone: object.customerPhone,
      dateTime: DateTime.fromMillisecondsSinceEpoch(object.timestamp),
      partySize: object.partySize,
      reservationStatus: ReservationStatus.values[object.statusIndex],
      tableId: object.tableId.isEmpty ? null : object.tableId,
      notes: object.notes.isEmpty ? null : object.notes,
    );
  }

  @override
  ReservationObject toObject() {
    return ReservationObject(
      id: id,
      customerName: name,
      customerPhone: customerPhone,
      timestamp: dateTime.millisecondsSinceEpoch,
      partySize: partySize,
      statusIndex: reservationStatus.index,
      tableId: tableId ?? '',
      notes: notes ?? '',
    );
  }

  @override
  int compareTo(Reservation other) => dateTime.compareTo(other.dateTime);

  @override
  String get logName => 'reservation.$name';
}

class ReservationObject extends ModelObject<Reservation> {
  final String? id;
  final String customerName;
  final String customerPhone;
  final int timestamp;
  final int partySize;
  final int statusIndex;
  final String tableId;
  final String notes;

  const ReservationObject({
    this.id,
    required this.customerName,
    required this.customerPhone,
    required this.timestamp,
    this.partySize = 2,
    this.statusIndex = 0,
    this.tableId = '',
    this.notes = '',
  });

  @override
  Map<String, Object> toMap() {
    return {
      'customerName': customerName,
      'customerPhone': customerPhone,
      'timestamp': timestamp,
      'partySize': partySize,
      'statusIndex': statusIndex,
      'tableId': tableId,
      'notes': notes,
    };
  }

  @override
  Map<String, Object> diff(Reservation model) {
    final result = <String, Object>{};
    final prefix = model.prefix;

    if (customerName != model.name) {
      model.name = customerName;
      result['$prefix.customerName'] = customerName;
    }
    if (customerPhone != model.customerPhone) {
      model.customerPhone = customerPhone;
      result['$prefix.customerPhone'] = customerPhone;
    }
    final newTs = DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (newTs != model.dateTime) {
      model.dateTime = newTs;
      result['$prefix.timestamp'] = timestamp;
    }
    if (partySize != model.partySize) {
      model.partySize = partySize;
      result['$prefix.partySize'] = partySize;
    }
    if (statusIndex != model.reservationStatus.index) {
      model.reservationStatus = ReservationStatus.values[statusIndex];
      result['$prefix.statusIndex'] = statusIndex;
    }
    final tid = tableId;
    if (tid != (model.tableId ?? '')) {
      model.tableId = tid.isEmpty ? null : tid;
      result['$prefix.tableId'] = tid;
    }
    if (notes != (model.notes ?? '')) {
      model.notes = notes.isEmpty ? null : notes;
      result['$prefix.notes'] = notes;
    }
    return result;
  }

  factory ReservationObject.build(Map<String, Object?> data) {
    return ReservationObject(
      id: data['id'] as String?,
      customerName: data['customerName'] as String? ?? '',
      customerPhone: data['customerPhone'] as String? ?? '',
      timestamp: data['timestamp'] as int? ?? 0,
      partySize: data['partySize'] as int? ?? 2,
      statusIndex: data['statusIndex'] as int? ?? 0,
      tableId: data['tableId'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
    );
  }
}