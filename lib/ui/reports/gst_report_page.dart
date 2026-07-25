import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/models/repository/seller.dart';
import 'package:hotel_pos_system/services/tax_config.dart';
import 'package:intl/intl.dart';

/// GST report page — shows a date-range breakdown of sales with CGST/SGST
/// split, totals, and a print/PDF export button.
class GstReportPage extends StatefulWidget {
  const GstReportPage({super.key});

  @override
  State<GstReportPage> createState() => _GstReportPageState();
}

class _GstReportPageState extends State<GstReportPage> {
  DateTimeRange? _range;
  GstReport? _report;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Default to last 30 days
    final now = DateTime.now();
    _range = DateTimeRange(
      start: now.subtract(const Duration(days: 30)),
      end: now,
    );
    _loadReport();
  }

  Future<void> _loadReport() async {
    if (_range == null) return;
    setState(() => _loading = true);
    try {
      final report = await _buildReport(_range!);
      setState(() {
        _report = report;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<GstReport> _buildReport(DateTimeRange range) async {
    final rows = <GstReportRow>[];
    var totalOrders = 0;
    var totalGross = 0.0;
    var totalTaxable = 0.0;
    var totalCgst = 0.0;
    var totalSgst = 0.0;
    var totalTax = 0.0;
    var totalNet = 0.0;

    // Iterate day by day
    for (var d = range.start;
        d.isBefore(range.end.add(const Duration(days: 1)));
        d = d.add(const Duration(days: 1))) {
      final dayStart = DateTime(d.year, d.month, d.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final metrics = await Seller.instance.getMetrics(dayStart, dayEnd);
      final gross = metrics.revenue.toDouble();
      final tax = TaxConfig.instance.calculate(gross);
      if (metrics.count > 0 || gross > 0) {
        rows.add(GstReportRow(
          date: dayStart,
          orderCount: metrics.count,
          grossSales: gross,
          taxableAmount: tax.taxableAmount,
          cgst: tax.cgst,
          sgst: tax.sgst,
          totalTax: tax.totalTax,
          netSales: gross + tax.totalTax,
        ));
        totalOrders += metrics.count;
        totalGross += gross;
        totalTaxable += tax.taxableAmount;
        totalCgst += tax.cgst;
        totalSgst += tax.sgst;
        totalTax += tax.totalTax;
        totalNet += gross + tax.totalTax;
      }
    }

    return GstReport(
      start: range.start,
      end: range.end,
      rows: rows,
      totalOrders: totalOrders,
      totalGrossSales: totalGross,
      totalTaxableAmount: totalTaxable,
      totalCgst: totalCgst,
      totalSgst: totalSgst,
      totalTax: totalTax,
      totalNetSales: totalNet,
    );
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _range,
    );
    if (picked != null) {
      setState(() => _range = picked);
      _loadReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GST Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_outlined),
            onPressed: _pickRange,
            tooltip: 'Select date range',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : _report == null
              ? const Center(child: Text('No data'))
              : _buildReportView(context, _report!),
    );
  }

  Widget _buildReportView(BuildContext context, GstReport report) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFmt = DateFormat.yMMMd();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Date range + summary cards
        _SummaryCard(report: report, dateFmt: dateFmt),
        const SizedBox(height: 16),
        // Per-day breakdown
        Text('Daily Breakdown', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        ...report.rows.map((row) => _ReportRowCard(row: row, fmt: fmt, dateFmt: dateFmt)),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final GstReport report;
  final DateFormat dateFmt;
  const _SummaryCard({required this.report, required this.dateFmt});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${dateFmt.format(report.start)} — ${dateFmt.format(report.end)}',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _KpiTile(label: 'Orders', value: '${report.totalOrders}'),
                ),
                Expanded(
                  child: _KpiTile(label: 'Gross Sales', value: fmt.format(report.totalGrossSales)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _KpiTile(label: 'CGST', value: fmt.format(report.totalCgst), color: BrandColors.success)),
                Expanded(child: _KpiTile(label: 'SGST', value: fmt.format(report.totalSgst), color: BrandColors.success)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _KpiTile(label: 'Total Tax', value: fmt.format(report.totalTax), color: BrandColors.warning)),
                Expanded(child: _KpiTile(label: 'Net (incl. tax)', value: fmt.format(report.totalNetSales), color: BrandColors.gold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _KpiTile({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ReportRowCard extends StatelessWidget {
  final GstReportRow row;
  final NumberFormat fmt;
  final DateFormat dateFmt;
  const _ReportRowCard({required this.row, required this.fmt, required this.dateFmt});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateFmt.format(row.date), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                  Text('${row.orderCount} orders', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
                ],
              ),
            ),
            Expanded(
              child: Text(fmt.format(row.grossSales), style: GoogleFonts.plusJakartaSans(fontSize: 12), textAlign: TextAlign.end),
            ),
            Expanded(
              child: Text(fmt.format(row.totalTax), style: GoogleFonts.plusJakartaSans(fontSize: 12, color: BrandColors.warning), textAlign: TextAlign.end),
            ),
            Expanded(
              child: Text(fmt.format(row.netSales), style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700), textAlign: TextAlign.end),
            ),
          ],
        ),
      ),
    );
  }
}