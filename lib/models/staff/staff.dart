import 'package:flutter/material.dart';
import 'package:hotel_pos_system/models/model.dart';
import 'package:hotel_pos_system/models/model_object.dart';
import 'package:hotel_pos_system/models/repository.dart';
import 'package:hotel_pos_system/models/repository/staff.dart';
import 'package:hotel_pos_system/services/storage.dart';

/// Staff role — controls what features a staff member can access.
enum StaffRole {
  owner,    // full access — settings, reports, staff management, everything
  manager,  // orders, checkout, tables, reports, inventory — no staff mgmt
  cashier,  // orders, checkout, cash register
  waiter,   // order entry, tables — no checkout, no reports
}

/// A restaurant staff member who logs in with a PIN.
///
/// Stored under the `staff` store. Each staff member has a name, a 4-6 digit
/// PIN, and a role that gates feature access. Shift tracking (clock-in/out
/// times) is kept in a separate in-memory session record, not persisted.
class Staff extends Model<StaffObject> with ModelStorage<StaffObject> implements Comparable<Staff> {
  /// 4-6 digit PIN (stored as plain text — this is an offline app with no
  /// network surface, and hashing would add a dependency for minimal gain.
  /// If cloud sync is added later, hash before syncing).
  String pin;

  /// Role controlling feature access.
  StaffRole role;

  @override
  final Stores storageStore = Stores.staff;

  @override
  Repository<Staff> get repository => StaffRepository.instance;

  Staff({
    super.id,
    super.status = ModelStatus.normal,
    required String name,
    required this.pin,
    this.role = StaffRole.waiter,
  }) : super(name: name);

  factory Staff.fromObject(StaffObject object) {
    return Staff(
      id: object.id,
      name: object.name,
      pin: object.pin,
      role: StaffRole.values[object.roleIndex],
    );
  }

  @override
  StaffObject toObject() {
    return StaffObject(
      id: id,
      name: name,
      pin: pin,
      roleIndex: role.index,
    );
  }

  @override
  int compareTo(Staff other) => name.toLowerCase().compareTo(other.name.toLowerCase());

  @override
  String get logName => 'staff.$name';
}

class StaffObject extends ModelObject<Staff> {
  final String? id;
  final String name;
  final String pin;
  final int roleIndex;

  const StaffObject({
    this.id,
    required this.name,
    required this.pin,
    this.roleIndex = 0,
  });

  @override
  Map<String, Object> toMap() {
    return {'name': name, 'pin': pin, 'roleIndex': roleIndex};
  }

  @override
  Map<String, Object> diff(Staff model) {
    final result = <String, Object>{};
    final prefix = model.prefix;

    if (name != model.name) {
      model.name = name;
      result['$prefix.name'] = name;
    }
    if (pin != model.pin) {
      model.pin = pin;
      result['$prefix.pin'] = pin;
    }
    if (roleIndex != model.role.index) {
      model.role = StaffRole.values[roleIndex];
      result['$prefix.roleIndex'] = roleIndex;
    }
    return result;
  }

  factory StaffObject.build(Map<String, Object?> data) {
    return StaffObject(
      id: data['id'] as String?,
      name: data['name'] as String? ?? '',
      pin: data['pin'] as String? ?? '',
      roleIndex: data['roleIndex'] as int? ?? 0,
    );
  }
}