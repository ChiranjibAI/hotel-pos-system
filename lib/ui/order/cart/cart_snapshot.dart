import 'package:flutter/material.dart';
import 'package:hotel_pos_system/components/scrollable_draggable_sheet.dart';
import 'package:hotel_pos_system/components/style/hint_text.dart';
import 'package:hotel_pos_system/components/style/outlined_text.dart';
import 'package:hotel_pos_system/helpers/util.dart';
import 'package:hotel_pos_system/models/repository/cart.dart';
import 'package:hotel_pos_system/translator.dart';
import 'package:provider/provider.dart';

class CartSnapshot extends StatelessWidget {
  final ScrollableDraggableController controller;

  const CartSnapshot({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<Cart>();

    if (cart.isEmpty) {
      return Center(child: HintText(S.orderCartSnapshotEmpty));
    }

    return Padding(
      padding: const .symmetric(horizontal: 12.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              scrollDirection: .horizontal,
              padding: const .only(right: 16),
              itemCount: cart.products.length,
              itemBuilder: (context, index) {
                final product = cart.products[index];
                return GestureDetector(
                  onTap: () {
                    cart.toggleAll(false, except: product);
                    if (controller.isAttached) {
                      controller.jumpTo(controller.snapSizes[1]);
                    }
                  },
                  child: OutlinedText(
                    product.name,
                    key: Key('cart_snapshot.$index'),
                    margin: const .only(right: 8),
                    badge: product.count > 9 ? '9+' : product.count.toString(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 16.0),
          Text(
            cart.productsPrice.toCurrency(),
            key: const Key('cart_snapshot.price'),
            style: const TextStyle(fontWeight: .bold),
          ),
        ],
      ),
    );
  }
}
