import 'package:flutter/widgets.dart';
import 'package:hotel_pos_system/models/model.dart';
import 'package:hotel_pos_system/models/repository.dart';
import 'package:hotel_pos_system/models/staff/staff.dart';
import 'package:hotel_pos_system/services/storage.dart';

/// Repository of restaurant staff.
///
/// Same pattern as [Tables] — a singleton [ChangeNotifier] with
/// [RepositoryStorage]. Staff records are persisted in the `staff` store.
class StaffRepository extends ChangeNotifier with Repository<Staff>, RepositoryStorage<Staff> {
  static late StaffRepository instance;

  @override
  final Stores storageStore = Stores.staff;

  StaffRepository() {
    instance = this;
  }

  @override
  final RepositoryStorageType repoType = RepositoryStorageType.repoProperties;

  @override
  Staff buildItem(String id, Map<String, Object?> value) {
    return Staff.fromObject(StaffObject.build({'id': id, ...value}));
  }

  /// Find a staff member by PIN. Returns null if no match.
  Staff? findByPin(String pin) {
    for (final s in items) {
      if (s.pin == pin) return s;
    }
    return null;
  }

  /// Whether any staff member exists (used to decide whether to show the
  /// login screen). If no staff are configured, the app is in "open mode".
  bool get hasStaff => isNotEmpty;
}

/// Tracks the currently logged-in staff member and shift times.
///
/// This is the in-memory session state — not persisted. When the app restarts,
/// the user must log in again (if staff are configured). A [ChangeNotifier] so
/// the UI rebuilds when login state changes.
class StaffSession extends ChangeNotifier {
  static StaffSession instance = StaffSession();

  StaffSession();

  Staff? _current;
  DateTime? _clockIn;

  /// The currently logged-in staff member, or null if logged out / open mode.
  Staff? get current => _current;

  /// Whether a staff member is currently logged in.
  bool get isLoggedIn => _current != null;

  /// Whether staff login is required (staff configured + not logged in).
  bool get requiresLogin => StaffRepository.instance.hasStaff && _current == null;

  /// Clock-in time of the current session.
  DateTime? get clockIn => _clockIn;

  /// Log in a staff member by PIN. Returns true on success.
  bool login(String pin) {
    final staff = StaffRepository.instance.findByPin(pin);
    if (staff == null) return false;
    _current = staff;
    _clockIn = DateTime.now();
    notifyListeners();
    return true;
  }

  /// Log in directly with a staff object (used by the admin when creating
  /// the first staff member).
  void loginAs(Staff staff) {
    _current = staff;
    _clockIn = DateTime.now();
    notifyListeners();
  }

  /// Log out the current staff member.
  void logout() {
    _current = null;
    _clockIn = null;
    notifyListeners();
  }
}