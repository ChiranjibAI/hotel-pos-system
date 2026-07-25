import 'package:flutter/widgets.dart';
import 'package:hotel_pos_system/services/cache.dart';

/// Multi-outlet management — lets the owner switch between multiple restaurant
/// locations. The active outlet ID is stored in Cache. All data (orders, menu,
/// stock) is scoped to the active outlet by prefixing store records with the
/// outlet ID.
///
/// This is the architecture scaffolding — full multi-outlet data isolation
/// requires prefixing all Storage and Database operations with the outlet ID,
/// which is a larger refactor. For now, the outlet switcher works as a label
/// + preference that can be extended later.
class OutletService extends ChangeNotifier {
  static OutletService instance = OutletService();

  static const _activeKey = 'outlet.active';
  static const _listKey = 'outlet.list';

  /// The active outlet ID (null = default single-outlet mode).
  String? get activeId => Cache.instance.get<String>(_activeKey);

  /// The active outlet name.
  String get activeName => activeId ?? 'Main Outlet';

  /// List of configured outlets: [{id, name}].
  List<Map<String, String>> get outlets {
    final raw = Cache.instance.get<String>(_listKey);
    if (raw == null || raw.isEmpty) return [{'id': 'main', 'name': 'Main Outlet'}];
    try {
      final parts = raw.split(';');
      return parts.where((p) => p.isNotEmpty).map((p) {
        final kv = p.split(':');
        return {'id': kv[0], 'name': kv.length > 1 ? kv[1] : kv[0]};
      }).toList();
    } catch (_) {
      return [{'id': 'main', 'name': 'Main Outlet'}];
    }
  }

  /// Switch to a different outlet.
  Future<void> switchOutlet(String id) async {
    await Cache.instance.set<String>(_activeKey, id);
    notifyListeners();
  }

  /// Add a new outlet.
  Future<void> addOutlet(String id, String name) async {
    final list = outlets;
    if (list.any((o) => o['id'] == id)) return;
    list.add({'id': id, 'name': name});
    await _saveList(list);
    notifyListeners();
  }

  Future<void> _saveList(List<Map<String, String>> list) async {
    final raw = list.map((o) => '${o['id']}:${o['name']}').join(';');
    await Cache.instance.set<String>(_listKey, raw);
  }
}