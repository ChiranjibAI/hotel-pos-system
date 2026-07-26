import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/components/style/empty_body.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/services/forecast_service.dart';

/// Demand Forecasting page — shows 7-day revenue + order predictions.
class ForecastPage extends StatefulWidget {
  const ForecastPage({super.key});

  @override
  State<ForecastPage> createState() => _ForecastPageState();
}

class _ForecastPageState extends State<ForecastPage> {
  List<ForecastResult> _forecast = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final f = await ForecastService.instance.forecast7Days();
    if (mounted) setState(() { _forecast = f; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demand Forecast'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_outlined)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _forecast.isEmpty
              ? EmptyBody(
                  title: 'Not enough data yet',
                  content: 'Need 7+ days of order history to forecast. Keep selling!',
                  icon: Icons.trending_up_outlined,
                  onPressed: _load,
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final maxRevenue = _forecast.fold<num>(0, (a, f) => a > f.predictedRevenue ? a : f.predictedRevenue);
    final totalPredicted = _forecast.fold<num>(0, (a, f) => a + f.predictedRevenue);
    final totalOrders = _forecast.fold<int>(0, (a, f) => a + f.predictedOrders);
    final avgConfidence = _forecast.fold<double>(0, (a, f) => a + f.confidence) / _forecast.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('7-Day Forecast', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _stat('Revenue', '₹${totalPredicted.toStringAsFixed(0)}'),
                    _stat('Orders', '$totalOrders'),
                    _stat('Confidence', '${(avgConfidence * 100).round()}%'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('DAILY BREAKDOWN', style: GoogleFonts.plusJakartaSans(
          fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: BrandColors.gold,
        )),
        const SizedBox(height: 12),
        ..._forecast.map((f) => _buildDayRow(f, maxRevenue)),
        if (avgConfidence < 0.5) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BrandColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: BrandColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_outlined, color: BrandColors.warning, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'Low confidence — forecast improves with more order history (14+ days recommended).',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12),
                )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: BrandColors.gold)),
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color)),
      ],
    );
  }

  Widget _buildDayRow(ForecastResult f, num maxRevenue) {
    final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][f.date.weekday - 1];
    final barWidth = maxRevenue > 0 ? (f.predictedRevenue / maxRevenue) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text(dayName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13))),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: barWidth.clamp(0.0, 1.0),
                      child: Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: BrandColors.gold.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('₹${f.predictedRevenue.toStringAsFixed(0)} • ${f.predictedOrders} orders',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}