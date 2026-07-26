import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/components/style/empty_body.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/models/repository/seller.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Day-Part Analysis page — shows hourly sales distribution so the owner
/// knows which hours are busiest and when to schedule staff.
///
/// Uses Seller.getMetricsInPeriod with MetricsIntervalType.hour to get
/// per-hour order counts and revenue for the selected date range.
class DayPartPage extends StatefulWidget {
  const DayPartPage({super.key});

  @override
  State<DayPartPage> createState() => _DayPartPageState();
}

class _DayPartPageState extends State<DayPartPage> {
  DateTimeRange? _range;
  List<_HourData> _data = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
    _loadData();
  }

  Future<void> _loadData() async {
    if (_range == null) return;
    setState(() => _loading = true);
    try {
      // Get hourly metrics for the range
      final summaries = await Seller.instance.getMetricsInPeriod(
        _range!.start,
        _range!.end.add(const Duration(days: 1)),
        types: [OrderMetricType.count, OrderMetricType.revenue],
        interval: MetricsIntervalType.hour,
        ignoreEmpty: false,
      );

      // Aggregate by hour-of-day (0-23)
      final hourMap = <int, _HourData>{};
      for (final s in summaries) {
        final hour = s.at.hour;
        final existing = hourMap[hour] ?? _HourData(hour: hour);
        existing.count += s.count;
        existing.revenue += s.revenue;
        hourMap[hour] = existing;
      }

      // Fill missing hours with 0
      for (var h = 0; h < 24; h++) {
        hourMap[h] ??= _HourData(hour: h);
      }

      setState(() {
        _data = hourMap.values.toList()..sort((a, b) => a.hour.compareTo(b.hour));
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
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
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Day-Part Analysis'),
        actions: [
          IconButton(icon: const Icon(Icons.date_range_outlined), onPressed: _pickRange, tooltip: 'Select range'),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : _data.isEmpty
              ? const EmptyBody(title: 'No data', content: 'No orders in the selected range.', icon: Icons.bar_chart_outlined, onPressed: null)
              : _buildChart(context),
    );
  }

  Widget _buildChart(BuildContext context) {
    final maxRevenue = _data.fold<num>(0, (max, d) => d.revenue > max ? d.revenue : max);
    final peakHour = _data.fold<_HourData>(_data.first, (peak, d) => d.count > peak.count ? d : peak);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary
        Row(
          children: [
            Expanded(child: _SummaryTile(label: 'Peak Hour', value: '${peakHour.hour}:00', color: BrandColors.gold)),
            Expanded(child: _SummaryTile(label: 'Peak Orders', value: '${peakHour.count}', color: BrandColors.success)),
            Expanded(child: _SummaryTile(label: 'Max Revenue/hr', value: '\$${maxRevenue.toStringAsFixed(0)}', color: BrandColors.warning)),
          ],
        ),
        const SizedBox(height: 16),
        Text('Hourly Order Distribution', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        // Bar chart
        SizedBox(
          height: 280,
          child: SfCartesianChart(
            margin: const EdgeInsets.all(8),
            primaryXAxis: NumericAxis(
              interval: 2,
              title: AxisTitle(text: 'Hour of Day'),
              minimum: 0,
              maximum: 23,
            ),
            primaryYAxis: NumericAxis(title: AxisTitle(text: 'Orders')),
            series: [
              ColumnSeries<_HourData, int>(
                dataSource: _data,
                xValueMapper: (d, _) => d.hour,
                yValueMapper: (d, _) => d.count,
                color: BrandColors.gold,
                borderRadius: BorderRadius.circular(4),
                dataLabelSettings: DataLabelSettings(
                  isVisible: false,
                  textStyle: GoogleFonts.plusJakartaSans(fontSize: 10),
                ),
              ),
            ],
            tooltipBehavior: TooltipBehavior(enable: true, header: 'Hour', format: 'point.x:00 — point.y orders'),
          ),
        ),
        const SizedBox(height: 20),
        // Hourly breakdown list
        Text('Breakdown', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ..._data.where((d) => d.count > 0).map((d) => _HourRow(data: d)),
      ],
    );
  }
}

class _HourData {
  final int hour;
  int count;
  num revenue;
  _HourData({required this.hour, this.count = 0, this.revenue = 0});
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }
}

class _HourRow extends StatelessWidget {
  final _HourData data;
  const _HourRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final isPeak = data.count > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text('${data.hour.toString().padLeft(2, '0')}:00', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: data.count / (data.count > 0 ? data.count : 1),
                minHeight: 20,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                color: isPeak ? BrandColors.gold.withValues(alpha: 0.6) : Colors.transparent,
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: Text('${data.count} ord', style: GoogleFonts.plusJakartaSans(fontSize: 11), textAlign: TextAlign.end),
          ),
          SizedBox(
            width: 70,
            child: Text('\$${data.revenue.toStringAsFixed(0)}', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}