import 'package:flutter/material.dart';
import 'package:hotel_pos_system/components/scaffold/reorderable_scaffold.dart';
import 'package:hotel_pos_system/models/order/order_attribute.dart';
import 'package:hotel_pos_system/models/repository/order_attributes.dart';
import 'package:hotel_pos_system/translator.dart';

class OrderAttributeReorder extends StatelessWidget {
  const OrderAttributeReorder({super.key});

  @override
  Widget build(BuildContext context) {
    return ReorderableScaffold(
      items: OrderAttributes.instance.itemList,
      title: S.orderAttributeTitleReorder,
      handleSubmit: (List<OrderAttribute> items) => OrderAttributes.instance.reorderItems(items),
    );
  }
}
