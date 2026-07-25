import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hotel_pos_system/helpers/logger.dart';
import 'package:hotel_pos_system/services/cache.dart';
import 'package:hotel_pos_system/services/storage.dart';

/// Cloud sync service — architecture ready, activates when Supabase
/// credentials are configured.
///
/// This service is designed to be credential-gated: it reads Supabase URL
/// and anon key from [Cache] (set by the owner in Settings > Cloud Sync).
/// When credentials are present, it syncs local Stores data to a Supabase
/// table on a timer. When absent (the default offline build), it is a no-op.
///
/// This is the scaffolding — the actual HTTP calls to Supabase REST API
/// are stubbed with TODOs. To activate:
/// 1. Create a Supabase project at supabase.com
/// 2. Create a table: `pos_sync (id text primary key, store text, data jsonb, updated_at timestamptz, device_id text)`
/// 3. Set the Supabase URL + anon key in Settings > Cloud Sync
/// 4. Replace the TODO HTTP calls with dart:http calls to the Supabase REST API
///
/// Conflict resolution: last-write-wins by `updated_at` timestamp.
class CloudSyncService {
  static CloudSyncService instance = CloudSyncService();

  CloudSyncService();

  static const _urlKey = 'sync.supabase_url';
  static const _keyKey = 'sync.supabase_key';
  static const _deviceIdKey = 'sync.device_id';
  static const _lastSyncKey = 'sync.last_sync';

  /// Sync interval (when enabled).
  static const syncInterval = Duration(minutes: 5);

  Timer? _timer;
  bool _syncing = false;

  /// Whether sync is configured (URL + key present).
  bool get isConfigured {
    final url = Cache.instance.get<String>(_urlKey);
    final key = Cache.instance.get<String>(_keyKey);
    return url != null && url.isNotEmpty && key != null && key.isNotEmpty;
  }

  /// Supabase URL (e.g. https://xxx.supabase.co).
  String? get supabaseUrl => Cache.instance.get<String>(_urlKey);

  /// Supabase anon key.
  String? get supabaseKey => Cache.instance.get<String>(_keyKey);

  /// Unique device identifier (generated on first sync).
  String get deviceId {
    var id = Cache.instance.get<String>(_deviceIdKey);
    if (id == null || id.isEmpty) {
      id = 'dev_${DateTime.now().millisecondsSinceEpoch}';
      Cache.instance.set<String>(_deviceIdKey, id);
    }
    return id;
  }

  /// Last successful sync time.
  DateTime? get lastSync {
    final v = Cache.instance.get<int>(_lastSyncKey);
    return v == null ? null : DateTime.fromMillisecondsSinceEpoch(v);
  }

  /// Set Supabase credentials.
  Future<void> configure({required String url, required String key}) async {
    await Cache.instance.set<String>(_urlKey, url);
    await Cache.instance.set<String>(_keyKey, key);
  }

  /// Clear credentials and stop sync.
  Future<void> disable() async {
    await Cache.instance.set<String>(_urlKey, '');
    await Cache.instance.set<String>(_keyKey, '');
    stop();
  }

  /// Start the periodic sync timer. No-op if not configured.
  void start() {
    if (!isConfigured) return;
    _timer?.cancel();
    _timer = Timer.periodic(syncInterval, (_) => sync());
    // Initial sync after 10 seconds
    Future.delayed(const Duration(seconds: 10), () => sync());
  }

  /// Stop the sync timer.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Run a single sync: push local data to Supabase.
  Future<void> sync() async {
    if (!isConfigured || _syncing) return;
    _syncing = true;
    try {
      final data = await _collectAllData();
      await _pushToSupabase(data);
      await Cache.instance.set<int>(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
      Log.out('cloud sync complete', 'cloud_sync');
    } catch (e, s) {
      Log.err(e, 'cloud_sync_error', s);
    } finally {
      _syncing = false;
    }
  }

  /// Collect all stores into a JSON map.
  Future<Map<String, Object?>> _collectAllData() async {
    final result = <String, Object?>{};
    for (final store in Stores.values) {
      try {
        result[store.name] = await Storage.instance.get(store);
      } catch (_) {}
    }
    return result;
  }

  /// Push data to Supabase REST API.
  ///
  /// TODO: Replace with actual HTTP call:
  /// ```dart
  /// final response = await http.post(
  ///   Uri.parse('$supabaseUrl/rest/v1/pos_sync'),
  ///   headers: {
  ///     'apikey': supabaseKey!,
  ///     'Authorization': 'Bearer $supabaseKey',
  ///     'Content-Type': 'application/json',
  ///     'Prefer': 'resolution=merge-duplicates',
  ///   },
  ///   body: jsonEncode({
  ///     'id': deviceId,
  ///     'store': 'all',
  ///     'data': data,
  ///     'updated_at': DateTime.now().toUtc().toIso8601String(),
  ///     'device_id': deviceId,
  ///   }),
  /// );
  /// ```
  Future<void> _pushToSupabase(Map<String, Object?> data) async {
    // Stub — log the payload size so the owner can see sync is running.
    final payloadSize = jsonEncode(data).length;
    Log.out('sync payload: $payloadSize bytes (stub — wire HTTP when ready)', 'cloud_sync');
  }
}