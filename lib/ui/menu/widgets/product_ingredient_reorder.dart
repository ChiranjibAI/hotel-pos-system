import 'package:flutter/material.dart';
import 'package:hotel_pos_system/components/scaffold/reorderable_scaffold.dart';
import 'package:hotel_pos_system/models/menu/product.dart';
import 'package:hotel_pos_system/models/menu/product_ingredient.dart';
import 'package:hotel_pos_system/translator.dart';

class ProductIngredientReorder extends StatelessWidget {
  final Product product;

  const ProductIngredientReorder(this.product, {super.key});

  @override
  Widget build(BuildContext context) {
    return ReorderableScaffold(
      items: product.itemList,
      title: S.menuIngredientTitleReorder,
      handleSubmit: (List<ProductIngredient> items) => product.reorderItems(items),
    );
  }
}
