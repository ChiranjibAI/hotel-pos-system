import 'package:flutter/material.dart';
import 'package:hotel_pos_system/components/menu_actions.dart';
import 'package:hotel_pos_system/components/meta_block.dart';
import 'package:hotel_pos_system/components/slidable_item_list.dart';
import 'package:hotel_pos_system/components/style/buttons.dart';
import 'package:hotel_pos_system/components/style/route_buttons.dart';
import 'package:hotel_pos_system/constants/icons.dart';
import 'package:hotel_pos_system/models/menu/catalog.dart';
import 'package:hotel_pos_system/routes.dart';
import 'package:hotel_pos_system/translator.dart';

class MenuCatalogList extends StatelessWidget {
  final List<Catalog> catalogs;

  final Widget leading;
  final void Function(Catalog) onSelected;

  const MenuCatalogList(this.catalogs, {super.key, required this.onSelected, required this.leading});

  @override
  Widget build(BuildContext context) {
    return SlidableItemList<Catalog, _Action>(
      leading: leading,
      action: RouteIconButton(
        label: S.menuCatalogTitleReorder,
        icon: const Icon(KIcons.reorder),
        route: Routes.menuCatalogReorder,
        hideLabel: true,
      ),
      delegate: SlidableItemDelegate(
        items: catalogs,
        deleteValue: _Action.delete,
        tileBuilder: (catalog, _, actorBuilder) => _Tile(catalog, actorBuilder, onSelected),
        warningContentBuilder: _warningContentBuilder,
        actionBuilder: (Catalog catalog) => <MenuAction<_Action>>[
          MenuAction(
            title: Text(S.menuCatalogTitleUpdate),
            leading: const Icon(KIcons.modal),
            routePathParameters: {'id': catalog.id},
            route: Routes.menuCatalogUpdate,
          ),
          MenuAction(
            title: Text(S.menuProductTitleReorder),
            leading: const Icon(KIcons.reorder),
            route: Routes.menuProductReorder,
            routePathParameters: {'id': catalog.id},
          ),
        ],
        handleDelete: (item) => item.remove(),
      ),
    );
  }

  String _warningContentBuilder(BuildContext context, Catalog catalog) {
    final more = S.menuCatalogDialogDeletionContent(catalog.length);
    return S.dialogDeletionContent(catalog.name, '$more\n\n');
  }
}

class _Tile extends StatelessWidget {
  final Catalog catalog;
  final ActorBuilder actorBuilder;
  final void Function(Catalog) onSelected;

  const _Tile(this.catalog, this.actorBuilder, this.onSelected);

  @override
  Widget build(BuildContext context) {
    final actor = actorBuilder(context);

    return ListTile(
      key: Key('catalog.${catalog.id}'),
      leading: catalog.avator,
      title: Text(catalog.name),
      trailing: EntryMoreButton(onPressed: actor),
      subtitle: MetaBlock.withString(
        context,
        catalog.itemList.map((product) => product.name),
        emptyText: S.menuCatalogEmptyProducts,
      ),
      onLongPress: actor,
      onTap: () => onSelected(catalog),
    );
  }
}

enum _Action { delete }
