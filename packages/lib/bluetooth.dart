import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

/// Log level for the bluetooth/printer subsystem.
///
/// Mirrors `fbp.LogLevel` so callers can pass values interchangeably, but kept
/// as a separate enum so the public API of this package does not leak the
/// underlying BLE library.
enum LogLevel {
  none,
  error,
  warning,
  info,
  debug,
  verbose;

  fbp.LogLevel get _toFbp => fbp.LogLevel.values[index];
}

/// Logger facade for the bluetooth/printer subsystem.
///
/// App code uses `bt.Logger.level = bt.LogLevel.debug`. Internally we forward
/// to `flutter_blue_plus` so BLE traffic is visible in debug builds.
class Logger {
  Logger._();

  static LogLevel level = LogLevel.none;

  static void setLevel(LogLevel value, {bool color = true}) {
    level = value;
    fbp.FlutterBluePlus.setLogLevel(value._toFbp, color: color);
  }
}

/// RSSI → signal-quality buckets used by the printer UI.
enum BluetoothSignal {
  good(-60, 256),
  normal(-80, -60),
  weak(-256, -80);

  final int min;
  final int max;

  const BluetoothSignal(this.min, this.max);

  /// Map an RSSI value (dBm, typically -100..-40) to a signal bucket.
  static BluetoothSignal find(int rssi) {
    for (final v in values) {
      if (rssi >= v.min && rssi < v.max) return v;
    }
    return BluetoothSignal.weak;
  }
}

/// Printer hardware status, reported by the printer over BLE.
enum PrinterStatus {
  good(0),
  writeFailed(10),
  paperNotFound(20),
  paperJams(30),
  tooHot(40),
  lowBattery(50),
  printing(60),
  uncovering(70),
  noResponse(80),
  unrecoverable(90),
  unknown(100);

  final int priority;

  const PrinterStatus(this.priority);

  /// Pick the highest-priority (most severe) status from a set of bits.
  /// Different printers pack multiple error flags into a single status byte;
  /// we surface the most actionable one.
  static PrinterStatus fromMask(int mask) {
    PrinterStatus result = PrinterStatus.good;
    for (final v in values) {
      if ((mask & (1 << v.index)) != 0 && v.priority > result.priority) {
        result = v;
      }
    }
    return result;
  }
}

/// Print darkness / density. Most thermal printers support at least two.
enum PrinterDensity {
  normal,
  tight;
}

/// Thrown when the phone's Bluetooth adapter is off / unavailable.
class BluetoothOffException implements Exception {
  final String message;
  BluetoothOffException([this.message = 'Bluetooth adapter is off']);

  @override
  String toString() => 'BluetoothOffException: $message';
}

/// Re-exported exception types from flutter_blue_plus so app code can catch
/// them without importing the BLE library directly.
typedef BluetoothExceptionCode = fbp.FbpErrorCode;
typedef BluetoothException = fbp.FlutterBluePlusException;
typedef BluetoothExceptionFrom = fbp.ErrorPlatform;

/// Top-level BLE controller. Wraps `flutter_blue_plus` scan lifecycle.
class Bluetooth {
  static Bluetooth i = Bluetooth();

  StreamSubscription<List<fbp.ScanResult>>? _sub;
  final StreamController<List<BluetoothDevice>> _results =
      StreamController<List<BluetoothDevice>>.broadcast();

  /// Start a BLE scan for connectable devices. Emits the current result set
  /// on every change. Scan auto-stops after [timeout] (default 60s).
  Stream<List<BluetoothDevice>> startScan({Duration timeout = const Duration(seconds: 60)}) {
    // Stop any in-flight scan first.
    stopScan();

    _sub = fbp.FlutterBluePlus.scanResults.listen(
      (results) {
        final devices = results
            .where((r) => r.advertisementData.connectable || r.device.isConnected)
            .map((r) => BluetoothDevice._fromScan(r.device, r.rssi))
            .toList();
        if (!_results.isClosed) _results.add(devices);
      },
      onError: (Object e, StackTrace s) {
        if (!_results.isClosed) _results.addError(e, s);
      },
    );

    fbp.FlutterBluePlus.startScan(timeout: timeout).catchError((Object e) {
      // Surface BLE errors (adapter off, permission denied) to the caller.
      if (e is fbp.FlutterBluePlusException && e.code == fbp.FbpErrorCode.adapterIsOff.index) {
        _results.addError(BluetoothOffException());
      } else {
        _results.addError(e);
      }
    });

    return _results.stream;
  }

  /// Stop the current scan if any.
  Future<void> stopScan() async {
    await _sub?.cancel();
    _sub = null;
    try {
      await fbp.FlutterBluePlus.stopScan();
    } catch (_) {
      // Ignore — scan may already be stopped.
    }
  }

  /// Return currently-paired/bonded devices. flutter_blue_plus does not expose
  /// a system bond list on all platforms, so we fall back to the last scan.
  Future<List<BluetoothDevice>> pairedDevices() async {
    final last = fbp.FlutterBluePlus.lastScanResults;
    return last
        .map((r) => BluetoothDevice._fromScan(r.device, r.rssi))
        .toList();
  }

  /// Connect to a device by its remote id (platform-specific address).
  Future<BluetoothDevice> connect(String address) async {
    final device = fbp.BluetoothDevice.fromId(address);
    await device.connect(autoConnect: false);
    return BluetoothDevice._(device);
  }
}

/// A discovered or connected BLE device.
class BluetoothDevice {
  final fbp.BluetoothDevice _device;

  /// Most recent RSSI seen during scanning. `-256` when unknown.
  int rssi;

  BluetoothDevice._(this._device, {this.rssi = -256});

  factory BluetoothDevice._fromScan(fbp.BluetoothDevice device, int rssi) {
    return BluetoothDevice._(device, rssi: rssi);
  }

  /// A fake device for UI testing in debug mode. The app calls
  /// `BluetoothDevice.demo()` so a "demo" tile appears in the scan list when
  /// no real devices are nearby.
  factory BluetoothDevice.demo() {
    return BluetoothDevice._(_DemoDevice.instance, rssi: -50);
  }

  /// Advertised / platform name of the device (e.g. "XP-58" or "MHT-58").
  String get name => _device.platformName.isNotEmpty
      ? _device.platformName
      : (_device.advName.isNotEmpty ? _device.advName : '');

  /// Platform-specific address (MAC on Android, UUID on iOS).
  String get address => _device.remoteId.str;

  /// Whether the device is currently connected.
  bool get connected => _device.isConnected;

  /// Connection state changes.
  Stream<bool> get connectionState =>
      _device.connectionState.map((s) => s == fbp.BluetoothConnectionState.connected);

  /// Current MTU. Returns 0 when not connected.
  int get mtu => _device.mtuNow;

  /// Connect to the device.
  Future<void> connect() async {
    await _device.connect(autoConnect: false);
  }

  /// Disconnect from the device. Safe to call when already disconnected.
  Future<void> disconnect() async {
    if (_device is _DemoDevice) return;
    try {
      await _device.disconnect();
    } catch (_) {
      // Ignore — may already be disconnected.
    }
  }

  /// Discover GATT services and return the one matching [serviceUuid] (hex
  /// string, e.g. '18f0' or '000018f0-0000-1000-8000-00805f9b34fb').
  BluetoothService? getService(int id) {
    final target = _normalizeUuid(id);
    for (final s in _device.servicesList) {
      if (_uuidEquals(s.serviceUuid, target)) {
        return BluetoothService._(s);
      }
    }
    return null;
  }

  /// Stream of signal-quality updates. Polls RSSI while connected; emits
  /// [BluetoothSignal.weak] if the read fails.
  Stream<BluetoothSignal> createSignalStream({
    Duration interval = const Duration(minutes: 1),
  }) {
    if (_device is _DemoDevice) {
      return Stream.value(BluetoothSignal.good);
    }
    BluetoothSignal lastSignal = BluetoothSignal.weak;
    return Stream<BluetoothSignal>.periodic(interval, (_) => lastSignal).asyncMap((_) async {
      try {
        final r = await _device.readRssi();
        lastSignal = BluetoothSignal.find(r);
        return lastSignal;
      } catch (_) {
        return BluetoothSignal.weak;
      }
    });
  }
}

/// A discovered GATT service and its characteristics.
class BluetoothService {
  final fbp.BluetoothService _service;

  BluetoothService._(this._service);

  bool hasCharacteristic(int id) => getCharacteristic(id) != null;

  BluetoothCharacteristic? getCharacteristic(int id) {
    final target = _normalizeUuid(id);
    for (final c in _service.characteristics) {
      if (_uuidEquals(c.characteristicUuid, target)) {
        return BluetoothCharacteristic._(c);
      }
    }
    return null;
  }
}

/// A GATT characteristic — the channel over which receipt data and status
/// bytes are exchanged with the printer.
class BluetoothCharacteristic {
  final fbp.BluetoothCharacteristic _char;

  BluetoothCharacteristic._(this._char);

  /// Enable notifications/subscriptions so [read] emits values pushed by the
  /// printer (e.g. status bytes). Returns true on success.
  Future<bool> watch() async {
    try {
      await _char.setNotifyValue(true);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Stream of values received from the printer (via notifications or reads).
  Stream<Uint8List> read() {
    return _char.onValueReceived.map((list) => Uint8List.fromList(list));
  }

  /// Write a command payload to the printer. Uses write-with-response for
  /// reliability unless [withoutResponse] is set (used for high-throughput
  /// image data on printers that support it).
  Future<void> write(Uint8List data, {bool withoutResponse = false}) async {
    await _char.write(data, withoutResponse: withoutResponse);
  }
}

/// A printer manufacturer protocol. Each concrete subclass knows how to:
///  - prepare the printer for a new job (init + select justification)
///  - turn a 1-bit image bitmap into the printer's raster command stream
///  - query the realtime status byte(s) and decode them into [PrinterStatus]
abstract class PrinterManufactory {
  final int serviceUuid;
  final int writerChar;
  final int readerChar;
  final int widthMM;
  final int widthBits;

  const PrinterManufactory({
    this.serviceUuid = 0,
    this.writerChar = 0,
    this.readerChar = 0,
    this.widthMM = 0,
    this.widthBits = 0,
  });

  /// Initialisation commands sent before each job.
  Uint8List prepare() => Uint8List(0);

  /// Convert a 1-bit packed image (width = [widthBits], rows byte-aligned to 8)
  /// into the printer's raster command stream.
  Uint8List toCommands(Uint8List image, {required PrinterDensity density}) => Uint8List(0);

  /// Query the printer status. [writer]/[reader] are the GATT characteristics
  /// for sending commands and receiving responses.
  Future<PrinterStatus> getStatus({
    required fbp.BluetoothCharacteristic writer,
    required fbp.BluetoothCharacteristic reader,
  }) async =>
      PrinterStatus.unknown;

  /// Try to guess the manufacturer from the advertised device name.
  /// Returns `null` when the name doesn't match any known printer.
  static PrinterManufactory? tryGuess(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('xprinter') || lower.contains('xp-58') || lower.contains('xp-76') ||
        lower.contains('xp-80') || lower.contains('xp-80')) {
      return const XPrinter();
    }
    if (lower.contains('yokoscan')) {
      return const YokoscanPrinter();
    }
    if (lower.contains('cat') || lower.contains('mht')) {
      return const CatPrinter();
    }
    return null;
  }

  @override
  String toString() => runtimeType.toString();
}

/// Per-printer connection + drawing state, wired into the app's
/// `ChangeNotifier` tree so the UI rebuilds on connect/disconnect/status.
class Printer extends ChangeNotifier {
  final String address;
  final PrinterManufactory manufactory;

  bool _connected = false;
  Stream<PrinterStatus> statusStream = Stream.value(PrinterStatus.unknown);

  BluetoothDevice? device;
  fbp.BluetoothCharacteristic? writer;
  fbp.BluetoothCharacteristic? reader;

  Printer({
    this.address = '',
    this.manufactory = const CatPrinter(),
    Printer? other,
  }) {
    if (other != null) {
      _connected = other._connected;
      device = other.device;
      writer = other.writer;
      reader = other.reader;
    }
  }

  bool get connected => _connected;

  /// Establish the GATT connection and discover the writer/reader chars.
  Future<bool> connect() async {
    if (manufactory.serviceUuid == 0) return false;

    try {
      final dev = fbp.BluetoothDevice.fromId(address);
      await dev.connect(autoConnect: false);
      final services = await dev.discoverServices();

      final targetService = _normalizeUuid(manufactory.serviceUuid);
      final targetWriter = _normalizeUuid(manufactory.writerChar);
      final targetReader = _normalizeUuid(manufactory.readerChar);

      fbp.BluetoothService? svc;
      for (final s in services) {
        if (_uuidEquals(s.serviceUuid, targetService)) {
          svc = s;
          break;
        }
      }
      if (svc == null) {
        await dev.disconnect();
        return false;
      }

      for (final c in svc.characteristics) {
        if (_uuidEquals(c.characteristicUuid, targetWriter)) writer = c;
        if (_uuidEquals(c.characteristicUuid, targetReader)) reader = c;
      }
      if (writer == null) {
        await dev.disconnect();
        return false;
      }

      device = BluetoothDevice._(dev);
      _connected = true;
      notifyListeners();

      // Start listening for status updates if a reader char is available.
      if (reader != null) {
        try {
          await reader!.setNotifyValue(true);
          statusStream = reader!.onValueReceived.map((raw) {
            final bytes = Uint8List.fromList(raw);
            return manufactory is XPrinter
                ? _XPrinterStatus.decode(bytes)
                : (manufactory is YokoscanPrinter
                    ? _YokoscanStatus.decode(bytes)
                    : PrinterStatus.unknown);
          });
        } catch (_) {
          // Status subscription is best-effort.
        }
      }
      return true;
    } catch (e) {
      _connected = false;
      notifyListeners();
      return false;
    }
  }

  /// Disconnect from the printer. Safe to call when already disconnected.
  Future<void> disconnect() async {
    if (device == null) return;
    try {
      await device!.disconnect();
    } catch (_) {}
    _connected = false;
    writer = null;
    reader = null;
    notifyListeners();
  }

  /// Draw a 1-bit image to the printer, emitting progress (0.0 → 1.0) as
  /// chunks are written. Chunks respect the negotiated MTU so we don't
  /// overflow the BLE write buffer.
  Stream<double> draw(
    Uint8List image, {
    PrinterDensity density = PrinterDensity.normal,
  }) async* {
    if (!_connected || writer == null) {
      yield 0.0;
      return;
    }
    try {
      // 1. Initialise the printer.
      final prepare = manufactory.prepare();
      if (prepare.isNotEmpty) await writer!.write(prepare, withoutResponse: true);

      // 2. Convert image to the printer's command stream.
      final commands = manufactory.toCommands(image, density: density);
      if (commands.isEmpty) {
        yield 1.0;
        return;
      }

      // 3. Chunk the command payload by MTU (minus 3 bytes ATT header).
      //    For withoutResponse writes the stack enforces its own limit, but
      //    splitting here keeps the progress stream meaningful and avoids
      //    hitting the Android 20-byte default MTU before negotiation.
      final mtu = (device?.mtu ?? 23) - 3;
      final chunkSize = mtu > 20 ? mtu : 20;
      var sent = 0;
      while (sent < commands.length) {
        final end = (sent + chunkSize > commands.length)
            ? commands.length
            : sent + chunkSize;
        final chunk = Uint8List.sublistView(commands, sent, end);
        await writer!.write(chunk, withoutResponse: true);
        sent = end;
        yield sent / commands.length;
      }

      // 4. Final flush + feed.
      await writer!.write(_feedCutCommands(), withoutResponse: true);
      yield 1.0;
    } catch (e) {
      yield 0.0;
    }
  }

  /// Standard ESC/POS feed + partial-cut commands. Most thermal printers
  /// support these; harmless on those that don't.
  Uint8List _feedCutCommands() {
    return Uint8List.fromList([
      0x1B, 0x4A, 0x03, // ESC J 3 — feed 3 lines
      0x1D, 0x56, 0x01, // GS V 1 — partial cut
    ]);
  }
}

/// "Cat" printer protocol (used by CatPrinter / MHT-class devices).
///
/// These printers expose a proprietary GATT service. Image data is sent as
/// a sequence of row-packets, each prefixed with a small header.
class CatPrinter extends PrinterManufactory {
  final int feedPaperByteSize;

  const CatPrinter({this.feedPaperByteSize = 1})
      : super(
          serviceUuid: 0xff00,
          writerChar: 0xff02,
          readerChar: 0xff01,
          widthMM: 58,
          widthBits: 384,
        );

  @override
  Uint8List prepare() => Uint8List.fromList([
        0x1B, 0x40, // ESC @ — init
        0x1B, 0x21, 0x00, // ESC ! 0 — cancel all styles
        0x1B, 0x61, 0x01, // ESC a 1 — centre alignment
      ]);

  @override
  Uint8List toCommands(Uint8List image, {required PrinterDensity density}) {
    // Cat printers use a row-based protocol. Each row is `widthBits / 8` bytes
    // prefixed with a 4-byte header: [0x51, 0x00, rowIdx, 0x00].
    final rowBytes = widthBits ~/ 8;
    final rows = image.length ~/ rowBytes;
    final out = <int>[];
    for (var r = 0; r < rows; r++) {
      out.addAll([0x51, 0x00, r & 0xFF, 0x00]);
      out.addAll(image.sublist(r * rowBytes, (r + 1) * rowBytes));
    }
    // Trailing feed.
    for (var i = 0; i < feedPaperByteSize; i++) {
      out.addAll([0x51, 0x00, 0xFF, 0x00]);
    }
    return Uint8List.fromList(out);
  }

  @override
  Future<PrinterStatus> getStatus({
    required fbp.BluetoothCharacteristic writer,
    required fbp.BluetoothCharacteristic reader,
  }) async {
    // Cat printers report a single status byte on the reader char.
    try {
      final raw = await reader.read(timeout: 3);
      if (raw.isEmpty) return PrinterStatus.unknown;
      return _CatStatus.decode(Uint8List.fromList(raw));
    } catch (_) {
      return PrinterStatus.unknown;
    }
  }
}

/// ESC/POS-compatible 58/76/80mm thermal printers (XPrinter XP-58/76/80 and
/// clones). These are the most common receipt printers in small restaurants.
///
/// Protocol: standard ESC/POS GS v 0 raster bitmap command, plus realtime
/// status queries (DLE EOT n) for paper / error / cover status.
class XPrinter extends PrinterManufactory {
  const XPrinter({super.widthMM = 58, super.widthBits = 384})
      : super(
          serviceUuid: 0x18f0,
          writerChar: 0x2af1,
          readerChar: 0x2af0,
        );

  @override
  Uint8List prepare() => Uint8List.fromList([
        0x1B, 0x40, // ESC @ — init
        0x1B, 0x21, 0x00, // ESC ! 0 — cancel styles
        0x1B, 0x61, 0x01, // ESC a 1 — centre
        0x1D, 0x21, 0x00, // GS ! 0 — default char size
        0x1B, 0x33, 0x08, // ESC 3 8 — 8/216" line spacing
      ]);

  @override
  Uint8List toCommands(Uint8List image, {required PrinterDensity density}) {
    // GS v 0 — print raster bitmap.
    // Format: 1D 76 30 m xL xH yL yH d1...dn
    //   m = 0 (normal) or 1 (double width/height)
    //   x = bytes per row = widthBits / 8
    //   y = number of rows
    final x = widthBits ~/ 8;
    final y = image.length ~/ x;
    final xL = x & 0xFF;
    final xH = (x >> 8) & 0xFF;
    final yL = y & 0xFF;
    final yH = (y >> 8) & 0xFF;

    final out = <int>[
      0x1D, 0x76, 0x30, 0x00, // GS v 0 m=0
      xL, xH, yL, yH,
    ];
    out.addAll(image);
    return Uint8List.fromList(out);
  }

  @override
  Future<PrinterStatus> getStatus({
    required fbp.BluetoothCharacteristic writer,
    required fbp.BluetoothCharacteristic reader,
  }) async {
    try {
      // DLE EOT 1 — realtime printer status
      await writer.write(Uint8List.fromList([0x10, 0x04, 0x01]));
      final raw = await reader.read(timeout: 3);
      return _XPrinterStatus.decode(Uint8List.fromList(raw));
    } catch (_) {
      return PrinterStatus.unknown;
    }
  }
}

/// Yokoscan 58/80mm thermal printers. Use a GATT service similar to XPrinter
/// but with a different status-byte encoding.
class YokoscanPrinter extends PrinterManufactory {
  const YokoscanPrinter({super.widthMM = 58, super.widthBits = 384})
      : super(
          serviceUuid: 0xff00,
          writerChar: 0xff02,
          readerChar: 0xff01,
        );

  @override
  Uint8List prepare() => Uint8List.fromList([
        0x1B, 0x40,
        0x1B, 0x21, 0x00,
        0x1B, 0x61, 0x01,
      ]);

  @override
  Uint8List toCommands(Uint8List image, {required PrinterDensity density}) {
    // Yokoscan uses the same GS v 0 raster command as XPrinter.
    final x = widthBits ~/ 8;
    final y = image.length ~/ x;
    final xL = x & 0xFF;
    final xH = (x >> 8) & 0xFF;
    final yL = y & 0xFF;
    final yH = (y >> 8) & 0xFF;

    final out = <int>[
      0x1D, 0x76, 0x30, 0x00,
      xL, xH, yL, yH,
    ];
    out.addAll(image);
    return Uint8List.fromList(out);
  }

  @override
  Future<PrinterStatus> getStatus({
    required fbp.BluetoothCharacteristic writer,
    required fbp.BluetoothCharacteristic reader,
  }) async {
    try {
      final raw = await reader.read(timeout: 3);
      return _YokoscanStatus.decode(Uint8List.fromList(raw));
    } catch (_) {
      return PrinterStatus.unknown;
    }
  }
}

/// Epson printers — placeholder for future support. The app references
/// `bt.EpsonPrinter()` in commented-out enum values, so we keep the symbol
/// available to avoid breaking future uncommenting.
class EpsonPrinter extends PrinterManufactory {
  const EpsonPrinter()
      : super(
          serviceUuid: 0x18f0,
          writerChar: 0x2af1,
          readerChar: 0x2af0,
          widthMM: 80,
          widthBits: 576,
        );

  @override
  Uint8List prepare() => const CatPrinter().prepare();

  @override
  Uint8List toCommands(Uint8List image, {required PrinterDensity density}) {
    return const XPrinter().toCommands(image, density: density);
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Internal helpers
// ────────────────────────────────────────────────────────────────────────────

/// A no-op [fbp.BluetoothDevice] stand-in used by `BluetoothDevice.demo()`.
/// All methods are safe no-ops so the debug demo tile never crashes the UI.
class _DemoDevice implements fbp.BluetoothDevice {
  static const _DemoDevice instance = _DemoDevice();

  const _DemoDevice();

  @override
  fbp.DeviceIdentifier get remoteId => const fbp.DeviceIdentifier('demo');

  @override
  String get platformName => 'Demo Printer';

  @override
  String get advName => 'Demo Printer';

  @override
  bool get isConnected => false;

  @override
  Future<void> connect({
    Duration timeout = const Duration(seconds: 35),
    int? mtu = 512,
    bool autoConnect = false,
  }) async {}

  @override
  Future<void> disconnect({
    int timeout = 35,
    bool queue = true,
    int androidDelay = 2000,
  }) async {}

  @override
  Future<List<fbp.BluetoothService>> discoverServices({
    bool subscribeToServicesChanged = true,
    int timeout = 15,
  }) async => const [];

  @override
  Stream<fbp.BluetoothConnectionState> get connectionState =>
      Stream.value(fbp.BluetoothConnectionState.disconnected);

  @override
  int get mtuNow => 23;

  @override
  Stream<int> get mtu => Stream.value(23);

  @override
  Future<int> readRssi({int timeout = 15}) async => -50;

  @override
  List<fbp.BluetoothService> get servicesList => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Normalise a 16/32-bit UUID integer to the full 128-bit string form.
String _normalizeUuid(int id) {
  if (id == 0) return '';
  final hex = id.toRadixString(16).padLeft(4, '0');
  return '0000$hex-0000-1000-8000-00805f9b34fb';
}

/// Compare two UUIDs case-insensitively (handles short vs full forms).
bool _uuidEquals(fbp.Guid a, String b) {
  if (b.isEmpty) return false;
  final aStr = a.str.toLowerCase();
  final bStr = b.toLowerCase();
  return aStr == bStr || aStr.endsWith('-$bStr') || aStr == bStr.split('-').last;
}

/// Decode a Cat-printer status byte.
class _CatStatus {
  static PrinterStatus decode(Uint8List raw) {
    if (raw.isEmpty) return PrinterStatus.unknown;
    final b = raw[0];
    if (b & 0x08 != 0) return PrinterStatus.paperNotFound;
    if (b & 0x04 != 0) return PrinterStatus.tooHot;
    if (b & 0x02 != 0) return PrinterStatus.paperJams;
    if (b & 0x01 != 0) return PrinterStatus.lowBattery;
    return PrinterStatus.good;
  }
}

/// Decode an ESC/POS realtime status response (DLE EOT n reply).
///
/// Byte layout for n=1 (printer status):
///   bit 0: offline / online
///   bit 2: cover open
///   bit 3: paper feed (ignored)
///   bit 5: unrecoverable error
///   bit 6: auto-recoverable error
class _XPrinterStatus {
  static PrinterStatus decode(Uint8List raw) {
    if (raw.isEmpty) return PrinterStatus.unknown;
    final b = raw[0];
    if (b & 0x20 != 0) return PrinterStatus.unrecoverable;
    if (b & 0x40 != 0) return PrinterStatus.paperJams;
    if (b & 0x04 != 0) return PrinterStatus.uncovering;
    if (b == 0x36) return PrinterStatus.paperNotFound;
    return PrinterStatus.good;
  }
}

/// Yokoscan uses a proprietary status encoding similar to Cat.
class _YokoscanStatus {
  static PrinterStatus decode(Uint8List raw) {
    if (raw.isEmpty) return PrinterStatus.unknown;
    final b = raw[0];
    if (b & 0x08 != 0) return PrinterStatus.paperNotFound;
    if (b & 0x04 != 0) return PrinterStatus.tooHot;
    if (b & 0x02 != 0) return PrinterStatus.paperJams;
    return PrinterStatus.good;
  }
}