import 'package:flutter/material.dart';
import 'package:hotel_pos_system/components/scaffold/reorderable_scaffold.dart';
import 'package:hotel_pos_system/models/menu/catalog.dart';
import 'package:hotel_pos_system/models/repository/menu.dart';
import 'package:hotel_pos_system/translator.dart';

class CatalogReorder extends StatelessWidget {
  const CatalogReorder({super.key});

  @override
  Widget build(BuildContext context) {
    return ReorderableScaffold(
      items: Menu.instance.itemList,
      title: S.menuCatalogTitleReorder,
      handleSubmit: (List<Catalog> items) => Menu.instance.reorderItems(items),
    );
  }
}
