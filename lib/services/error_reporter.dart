import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:hotel_pos_system/helpers/logger.dart';

/// An in-memory ring buffer of recent errors captured at runtime.
///
/// This is the offline-first replacement for Firebase Crashlytics. When
/// Firebase is unavailable (which it is for the default offline build), this
/// service collects errors in a fixed-size ring buffer so the owner can view
/// them in the in-app Error Log page. The buffer is capped at [maxEntries]
/// (default 200) to avoid unbounded memory growth, and is process-scoped
/// (not persisted) — it is a live diagnostic tool, not a permanent record.
class ErrorReporter {
  static ErrorReporter instance = ErrorReporter();

  ErrorReporter();

  /// Maximum number of entries kept in the ring buffer.
  static const maxEntries = 200;

  final Queue<ErrorEntry> _entries = Queue();
  final List<VoidCallback> _listeners = [];

  List<ErrorEntry> get entries => _entries.toList();

  /// Record an error. Safe to call from anywhere; never throws.
  void record(Object error, StackTrace? stack, {String? context, bool fatal = false}) {
    final entry = ErrorEntry(
      error: error.toString(),
      stack: stack?.toString(),
      context: context ?? 'app',
      time: DateTime.now(),
      fatal: fatal,
    );
    _entries.addLast(entry);
    while (_entries.length > maxEntries) {
      _entries.removeFirst();
    }
    Log.out('error recorded: ${entry.error}', 'error_reporter');
    _notifyListeners();
  }

  /// Clear all recorded errors.
  void clear() {
    _entries.clear();
    _notifyListeners();
  }

  /// Register a listener that fires when entries change.
  void addListener(VoidCallback cb) {
    _listeners.add(cb);
  }

  void removeListener(VoidCallback cb) {
    _listeners.remove(cb);
  }

  void _notifyListeners() {
    for (final cb in List.of(_listeners)) {
      try {
        cb();
      } catch (_) {}
    }
  }
}

/// A single captured error entry.
class ErrorEntry {
  final String error;
  final String? stack;
  final String context;
  final DateTime time;
  final bool fatal;

  const ErrorEntry({
    required this.error,
    this.stack,
    required this.context,
    required this.time,
    this.fatal = false,
  });
}