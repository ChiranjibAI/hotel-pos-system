import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hotel_pos_system/helpers/logger.dart';
import 'package:hotel_pos_system/models/xfile.dart';
import 'package:hotel_pos_system/services/storage.dart';

/// A local auto-backup service that periodically exports all [Stores] data
/// to a timestamped JSON file on the device's documents directory.
///
/// This gives the restaurant owner a safety net: even if the main database is
/// corrupted or the phone is reset, the last backup can be restored manually.
/// Backups run automatically every [backupInterval] (default 12 hours) and on
/// every app launch. A maximum of [maxBackups] files are kept (older ones are
/// pruned) to avoid filling the device storage.
///
/// This is the offline-first alternative to cloud sync — no credentials, no
/// network dependency, no privacy concerns. The data never leaves the device.
class BackupService {
  static BackupService instance = BackupService();

  BackupService();

  /// How often to run an automatic backup.
  static const backupInterval = Duration(hours: 12);

  /// Maximum number of backup files to retain. Older files are pruned.
  static const maxBackups = 7;

  Timer? _timer;
  bool _running = false;

  /// Start the periodic backup timer. Call once from main.dart after init.
  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(backupInterval, (_) => runBackup());
    // Also run once shortly after startup (so launch always produces a fresh
    // backup without blocking app init).
    Future.delayed(const Duration(seconds: 30), () => runBackup());
  }

  /// Stop the periodic backup timer.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Run a single backup: read all stores, write a timestamped JSON file,
  /// prune old backups. Safe to call manually.
  Future<void> runBackup() async {
    if (_running) return;
    _running = true;
    try {
      final data = await _collectAllData();
      final dir = await _backupDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = XFile.fs.file('${dir.path}/backup_$timestamp.json');
      await file.writeAsString(jsonEncode(data));
      Log.out('backup written: ${file.path}', 'backup');
      await _pruneOldBackups(dir);
    } catch (e, s) {
      Log.err(e, 'backup_error', s);
    } finally {
      _running = false;
    }
  }

  /// Collect all stores into a single JSON-encodable map.
  Future<Map<String, Object?>> _collectAllData() async {
    final result = <String, Object?>{};
    for (final store in Stores.values) {
      try {
        final data = await Storage.instance.get(store);
        result[store.name] = data;
      } catch (e) {
        // Skip a store that fails rather than aborting the whole backup.
        Log.out('skip store ${store.name}: $e', 'backup');
      }
    }
    return result;
  }

  /// Get or create the backup directory under the app's documents folder.
  Future<Directory> _backupDirectory() async {
    final root = await XFile.getRootPath();
    final dir = XFile.fs.directory('${XFile.fs.path.dirname(root)}/backups');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Delete the oldest backups beyond [maxBackups].
  Future<void> _pruneOldBackups(Directory dir) async {
    try {
      final files = dir.listSync().whereType<File>().where((f) {
        return f.path.contains('backup_') && f.path.endsWith('.json');
      }).toList()
        ..sort((a, b) => a.path.compareTo(b.path)); // oldest first
      while (files.length > maxBackups) {
        final oldest = files.removeAt(0);
        await oldest.delete();
        Log.out('pruned backup: ${oldest.path}', 'backup');
      }
    } catch (e) {
      Log.out('prune failed: $e', 'backup');
    }
  }

  /// List existing backups for UI display.
  Future<List<BackupFileInfo>> listBackups() async {
    try {
      final dir = await _backupDirectory();
      final files = dir.listSync().whereType<File>().where((f) {
        return f.path.contains('backup_') && f.path.endsWith('.json');
      }).toList()
        ..sort((a, b) => b.path.compareTo(a.path)); // newest first
      return files.map((f) => BackupFileInfo(
        path: f.path,
        size: f.lengthSync(),
        modified: f.statSync().modified,
      )).toList();
    } catch (_) {
      return [];
    }
  }
}

/// Metadata about a single backup file.
class BackupFileInfo {
  final String path;
  final int size;
  final DateTime modified;
  const BackupFileInfo({required this.path, required this.size, required this.modified});

  String get name => path.split('/').last;
  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}