import 'package:flutter/widgets.dart';
import 'package:hotel_pos_system/models/model.dart';
import 'package:hotel_pos_system/models/model_object.dart';
import 'package:hotel_pos_system/models/repository.dart';
import 'package:hotel_pos_system/services/storage.dart';

/// Forward-declared repository setter — breaks the circular dependency
/// between customer.dart (model) and customers.dart (repository).
Repository<Customer>? _customersRepo;
set customersRepository(Repository<Customer> r) => _customersRepo = r;

/// A loyalty program customer, looked up by phone number.
///
/// Stored under the `customers` store. Points accumulate per order (1 point
/// per currency unit by default) and can be redeemed for a discount at
/// checkout. The redemption rate is configurable (default: 100 points = 1
/// currency unit off).
class Customer extends Model<CustomerObject> with ModelStorage<CustomerObject> implements Comparable<Customer> {
  /// Phone number (the lookup key).
  String phone;

  /// Total loyalty points accumulated.
  num points;

  /// Total amount spent across all orders (for analytics).
  num totalSpent;

  /// Number of orders placed.
  int orderCount;

  @override
  final Stores storageStore = Stores.customers;

  @override
  Repository<Customer> get repository => _customersRepo!;

  Customer({
    super.id,
    super.status = ModelStatus.normal,
    required String name,
    required this.phone,
    this.points = 0,
    this.totalSpent = 0,
    this.orderCount = 0,
  }) : super(name: name);

  factory Customer.fromObject(CustomerObject object) {
    return Customer(
      id: object.id,
      name: object.name,
      phone: object.phone,
      points: object.points,
      totalSpent: object.totalSpent,
      orderCount: object.orderCount,
    );
  }

  @override
  CustomerObject toObject() {
    return CustomerObject(
      id: id,
      name: name,
      phone: phone,
      points: points,
      totalSpent: totalSpent,
      orderCount: orderCount,
    );
  }

  @override
  int compareTo(Customer other) => name.toLowerCase().compareTo(other.name.toLowerCase());

  @override
  String get logName => 'customer.$name';
}

class CustomerObject extends ModelObject<Customer> {
  final String? id;
  final String name;
  final String phone;
  final num points;
  final num totalSpent;
  final int orderCount;

  const CustomerObject({
    this.id,
    required this.name,
    required this.phone,
    this.points = 0,
    this.totalSpent = 0,
    this.orderCount = 0,
  });

  @override
  Map<String, Object> toMap() {
    return {
      'name': name,
      'phone': phone,
      'points': points,
      'totalSpent': totalSpent,
      'orderCount': orderCount,
    };
  }

  @override
  Map<String, Object> diff(Customer model) {
    final result = <String, Object>{};
    final prefix = model.prefix;

    if (name != model.name) {
      model.name = name;
      result['$prefix.name'] = name;
    }
    if (phone != model.phone) {
      model.phone = phone;
      result['$prefix.phone'] = phone;
    }
    if (points != model.points) {
      model.points = points;
      result['$prefix.points'] = points;
    }
    if (totalSpent != model.totalSpent) {
      model.totalSpent = totalSpent;
      result['$prefix.totalSpent'] = totalSpent;
    }
    if (orderCount != model.orderCount) {
      model.orderCount = orderCount;
      result['$prefix.orderCount'] = orderCount;
    }
    return result;
  }

  factory CustomerObject.build(Map<String, Object?> data) {
    return CustomerObject(
      id: data['id'] as String?,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      points: data['points'] as num? ?? 0,
      totalSpent: data['totalSpent'] as num? ?? 0,
      orderCount: data['orderCount'] as int? ?? 0,
    );
  }
}