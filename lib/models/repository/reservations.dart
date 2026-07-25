import 'package:flutter/widgets.dart';
import 'package:hotel_pos_system/models/model.dart';
import 'package:hotel_pos_system/models/repository.dart';
import 'package:hotel_pos_system/models/reservation/reservation.dart' as model;
import 'package:hotel_pos_system/models/reservation/reservation.dart' show Reservation, ReservationObject;
import 'package:hotel_pos_system/services/storage.dart';

class ReservationsRepository extends ChangeNotifier with Repository<Reservation>, RepositoryStorage<Reservation> {
  static late ReservationsRepository instance;

  @override
  final Stores storageStore = Stores.reservations;

  ReservationsRepository() {
    instance = this;
    model.reservationsRepository = this;
  }

  @override
  final RepositoryStorageType repoType = RepositoryStorageType.repoProperties;

  @override
  Reservation buildItem(String id, Map<String, Object?> value) {
    return Reservation.fromObject(ReservationObject.build({'id': id, ...value}));
  }

  /// Get reservations for a specific date (by day, ignoring time).
  List<Reservation> forDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return items.where((r) => r.dateTime.isAfter(dayStart.subtract(const Duration(microseconds: 1))) &&
        r.dateTime.isBefore(dayEnd)).toList()..sort();
  }

  /// Upcoming reservations (today + future, sorted by time).
  List<Reservation> get upcoming {
    final now = DateTime.now();
    return items.where((r) => r.dateTime.isAfter(now.subtract(const Duration(hours: 1)))).toList()..sort();
  }
}