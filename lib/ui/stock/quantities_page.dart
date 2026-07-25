import 'package:flutter/material.dart';
import 'package:hotel_pos_system/components/style/empty_body.dart';
import 'package:hotel_pos_system/components/style/route_buttons.dart';
import 'package:hotel_pos_system/constants/icons.dart';
import 'package:hotel_pos_system/models/repository/quantities.dart';
import 'package:hotel_pos_system/routes.dart';
import 'package:hotel_pos_system/translator.dart';

import 'widgets/stock_quantity_list.dart';

class QuantitiesPage extends StatelessWidget {
  const QuantitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      key: const Key('quantities_page'),
      listenable: Quantities.instance,
      builder: (context, child) => _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (Quantities.instance.isEmpty) {
      return EmptyBody(content: S.stockQuantityEmptyBody, routeName: Routes.quantityCreate);
    }

    return SafeArea(
      child: StockQuantityList(
        quantities: Quantities.instance.itemList,
        leading: Row(
          children: [
            Expanded(
              child: RouteElevatedIconButton(
                key: const Key('quantity.add'),
                route: Routes.quantityCreate,
                label: S.stockQuantityTitleCreate,
                icon: const Icon(KIcons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
