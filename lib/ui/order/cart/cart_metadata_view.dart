import 'package:flutter/material.dart';
import 'package:hotel_pos_system/components/meta_block.dart';
import 'package:hotel_pos_system/helpers/util.dart';
import 'package:hotel_pos_system/models/repository/cart.dart';
import 'package:hotel_pos_system/translator.dart';
import 'package:hotel_pos_system/ui/order/cart/cart_actions.dart';
import 'package:provider/provider.dart';

class CartMetadataView extends StatelessWidget {
  const CartMetadataView({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<Cart>();

    return Row(
      children: <Widget>[
        const SizedBox(width: 16.0),
        const CartActions(),
        const SizedBox(width: 16.0),
        Expanded(
          key: const Key('cart.metadata'),
          child: MetaBlock.withString(context, <String>[
            S.orderCartMetaTotalCount(cart.productCount),
            S.orderCartMetaTotalPrice(cart.productsPrice.toCurrency()),
          ])!,
        ),
        const SizedBox(width: 16.0),
      ],
    );
  }
}
