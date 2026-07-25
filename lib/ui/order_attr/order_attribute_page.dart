import 'package:flutter/material.dart';
import 'package:hotel_pos_system/components/style/empty_body.dart';
import 'package:hotel_pos_system/components/style/hint_text.dart';
import 'package:hotel_pos_system/components/style/route_buttons.dart';
import 'package:hotel_pos_system/constants/constant.dart';
import 'package:hotel_pos_system/constants/icons.dart';
import 'package:hotel_pos_system/models/repository/order_attributes.dart';
import 'package:hotel_pos_system/routes.dart';
import 'package:hotel_pos_system/translator.dart';
import 'package:hotel_pos_system/ui/order_attr/widgets/order_attribute_tile.dart';

class OrderAttributePage extends StatelessWidget {
  const OrderAttributePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      key: const Key('order_attributes_page'),
      listenable: OrderAttributes.instance,
      builder: (context, child) => _buildBody(),
    );
  }

  Widget _buildBody() {
    if (OrderAttributes.instance.isEmpty) {
      return EmptyBody(content: S.orderAttributeEmptyBody, routeName: Routes.orderAttrCreate);
    }

    return SafeArea(
      child: ListView(
        padding: const .only(bottom: kFABSpacing, top: kTopSpacing),
        children: <Widget>[
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const .symmetric(horizontal: kHorizontalSpacing),
                  child: RouteElevatedIconButton(
                    key: const Key('order_attributes.add'),
                    icon: const Icon(KIcons.add),
                    label: S.orderAttributeTitleCreate,
                    route: Routes.orderAttrCreate,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(child: Center(child: HintText(S.totalCount(OrderAttributes.instance.length)))),
              RouteIconButton(
                key: const Key('order_attributes.reorder'),
                label: S.orderAttributeTitleReorder,
                route: Routes.orderAttrReorder,
                icon: const Icon(KIcons.reorder),
                hideLabel: true,
              ),
              const SizedBox(width: kHorizontalSpacing),
            ],
          ),
          const SizedBox(height: kInternalSpacing),
          for (final attribute in OrderAttributes.instance.itemList) OrderAttributeTile(attr: attribute),
        ],
      ),
    );
  }
}
