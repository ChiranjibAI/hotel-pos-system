import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hotel_pos_system/components/meta_block.dart';
import 'package:hotel_pos_system/components/models/order_loader.dart';
import 'package:hotel_pos_system/models/objects/order_object.dart';
import 'package:hotel_pos_system/routes.dart';
import 'package:hotel_pos_system/translator.dart';

class HistoryOrderList extends StatelessWidget {
  final ValueNotifier<DateTimeRange> notifier;

  const HistoryOrderList({super.key, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return OrderLoader(builder: _buildOrder, ranger: notifier);
  }

  Widget _buildOrder(BuildContext context, OrderObject order) {
    final subtitle = MetaBlock.withString(context, [
      S.analysisHistoryOrderListMetaNo(order.periodSeq.toString()),
      S.analysisHistoryOrderListMetaPaid(order.paid),
      S.analysisHistoryOrderListMetaPrice(order.price),
      S.analysisHistoryOrderListMetaProfit(order.profit),
    ]);

    return ListTile(
      key: Key('history.order.${order.id}'),
      leading: Padding(
        padding: const .only(top: 8.0),
        child: Text(DateFormat.Hm(S.localeName).format(order.createdAt)),
      ),
      title: MetaBlock.withString(
        context,
        order.products.map(
          (product) => product.count == 1 ? product.productName : '${product.productName} * ${product.count}',
        ),
      ),
      subtitle: subtitle,
      onTap: () => context.pushNamed(Routes.historyOrder, pathParameters: {'id': order.id?.toString() ?? ''}),
    );
  }
}
