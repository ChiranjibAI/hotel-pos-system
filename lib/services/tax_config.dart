import 'package:hotel_pos_system/services/cache.dart';

/// GST/Tax configuration service.
///
/// Stores the applicable tax rate (default 5% GST = 2.5% CGST + 2.5% SGST
/// for India restaurant sales). The rate is configurable from settings.
/// Tax is calculated on the total order price.
class TaxConfig {
  static TaxConfig instance = TaxConfig();

  TaxConfig();

  static const _rateKey = 'gst.taxRate';
  static const _enabledKey = 'gst.enabled';
  static const _labelKey = 'gst.label';

  /// Default GST rate for restaurant sales in India (5%).
  static const double defaultRate = 5.0;

  /// Whether GST is enabled.
  bool get enabled => Cache.instance.get<bool>(_enabledKey) ?? false;

  /// The tax rate percentage (e.g. 5.0 means 5%).
  double get rate {
    final v = Cache.instance.get<int>(_rateKey);
    if (v == null) return defaultRate;
    return v.toDouble();
  }

  /// Display label (e.g. "GST", "VAT").
  String get label => Cache.instance.get<String>(_labelKey) ?? 'GST';

  /// Enable/disable GST.
  Future<void> setEnabled(bool value) => Cache.instance.set<bool>(_enabledKey, value);

  /// Set the tax rate (as a percentage, e.g. 5.0 for 5%).
  Future<void> setRate(double value) => Cache.instance.set<int>(_rateKey, value.round());

  /// Set the display label.
  Future<void> setLabel(String value) => Cache.instance.set<String>(_labelKey, value);

  /// Calculate tax for a given amount.
  /// Returns (totalTax, cgst, sgst) where cgst = sgst = totalTax / 2.
  ({num totalTax, num cgst, num sgst, num taxableAmount}) calculate(num amount) {
    if (!enabled || amount <= 0) {
      return (totalTax: 0, cgst: 0, sgst: 0, taxableAmount: amount);
    }
    final totalTax = amount * rate / 100;
    return (
      totalTax: totalTax,
      cgst: totalTax / 2,
      sgst: totalTax / 2,
      taxableAmount: amount,
    );
  }
}

/// A single row in the GST report for a date.
class GstReportRow {
  final DateTime date;
  final int orderCount;
  final num grossSales;
  final num taxableAmount;
  final num cgst;
  final num sgst;
  final num totalTax;
  final num netSales;

  const GstReportRow({
    required this.date,
    required this.orderCount,
    required this.grossSales,
    required this.taxableAmount,
    required this.cgst,
    required this.sgst,
    required this.totalTax,
    required this.netSales,
  });
}

/// A GST report summary for a date range.
class GstReport {
  final DateTime start;
  final DateTime end;
  final List<GstReportRow> rows;
  final int totalOrders;
  final num totalGrossSales;
  final num totalTaxableAmount;
  final num totalCgst;
  final num totalSgst;
  final num totalTax;
  final num totalNetSales;

  const GstReport({
    required this.start,
    required this.end,
    required this.rows,
    required this.totalOrders,
    required this.totalGrossSales,
    required this.totalTaxableAmount,
    required this.totalCgst,
    required this.totalSgst,
    required this.totalTax,
    required this.totalNetSales,
  });
}