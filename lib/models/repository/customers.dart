import 'package:flutter/widgets.dart';
import 'package:hotel_pos_system/models/model.dart';
import 'package:hotel_pos_system/models/repository.dart';
import 'package:hotel_pos_system/models/customer/customer.dart' as model;
import 'package:hotel_pos_system/models/customer/customer.dart' show Customer, CustomerObject;
import 'package:hotel_pos_system/services/storage.dart';

/// Repository of loyalty program customers.
class Customers extends ChangeNotifier with Repository<Customer>, RepositoryStorage<Customer> {
  static late Customers instance;

  @override
  final Stores storageStore = Stores.customers;

  Customers() {
    instance = this;
    // Break circular dependency: register this repository with the model.
    model.customersRepository = this;
  }

  @override
  final RepositoryStorageType repoType = RepositoryStorageType.repoProperties;

  @override
  Customer buildItem(String id, Map<String, Object?> value) {
    return Customer.fromObject(CustomerObject.build({'id': id, ...value}));
  }

  /// Find a customer by phone number (exact match).
  Customer? findByPhone(String phone) {
    for (final c in items) {
      if (c.phone == phone) return c;
    }
    return null;
  }

  /// Add points to a customer after an order. Points = 1 per currency unit
  /// spent (configurable later). Also updates totalSpent + orderCount.
  Future<void> addPoints(Customer customer, num orderTotal) async {
    final newPoints = customer.points + orderTotal.floor();
    await customer.update(CustomerObject(
      name: customer.name,
      phone: customer.phone,
      points: newPoints,
      totalSpent: customer.totalSpent + orderTotal,
      orderCount: customer.orderCount + 1,
    ));
    notifyItems();
  }

  /// Redeem points for a discount. Returns the discount amount.
  /// Rate: 100 points = 1 currency unit off (configurable).
  Future<num> redeemPoints(Customer customer, num pointsToRedeem) async {
    if (pointsToRedeem > customer.points) return 0;
    final discount = pointsToRedeem / 100; // 100 pts = 1 unit
    await customer.update(CustomerObject(
      name: customer.name,
      phone: customer.phone,
      points: customer.points - pointsToRedeem,
      totalSpent: customer.totalSpent,
      orderCount: customer.orderCount,
    ));
    notifyItems();
    return discount;
  }
}