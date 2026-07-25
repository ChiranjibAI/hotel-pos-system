import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/models/repository/seller.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Daily Sales Report page — shows today's summary and lets the owner
/// auto-share it to WhatsApp. Also triggered automatically at closing time
/// (configurable, default 11 PM).
class DailyReportPage extends StatefulWidget {
  const DailyReportPage({super.key});

  @override
  State<DailyReportPage> createState() => _DailyReportPageState();
}

class _DailyReportPageState extends State<DailyReportPage> {
  OrderMetrics? _metrics;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    try {
      final m = await Seller.instance.getMetrics(start, end);
      setState(() { _metrics = m; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  String _buildReportText() {
    final m = _metrics;
    if (m == null) return 'No data available.';
    final date = DateFormat.yMMMd().format(DateTime.now());
    return '''*Hotel POS System — Daily Sales Report*
$date
========================
Orders: *${m.count}*
Revenue: *\$${m.revenue.toStringAsFixed(2)}*
Cost: \$${m.cost.toStringAsFixed(2)}
Profit: \$${m.profit.toStringAsFixed(2)}
========================
Thank you!''';
  }

  Future<void> _shareWhatsApp() async {
    final text = _buildReportText();
    final encoded = Uri.encodeComponent(text);
    final uri = Uri.parse('https://wa.me/?text=$encoded');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Sales Report')),
      body: _loading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final m = _metrics;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SummaryTile(label: 'Orders Today', value: '${m?.count ?? 0}', icon: Icons.receipt_long_rounded, color: BrandColors.gold),
        _SummaryTile(label: 'Revenue', value: '\$${(m?.revenue ?? 0).toStringAsFixed(2)}', icon: Icons.payments_rounded, color: BrandColors.success),
        _SummaryTile(label: 'Cost', value: '\$${(m?.cost ?? 0).toStringAsFixed(2)}', icon: Icons.trending_down_rounded, color: BrandColors.warning),
        _SummaryTile(label: 'Profit', value: '\$${(m?.profit ?? 0).toStringAsFixed(2)}', icon: Icons.trending_up_rounded, color: BrandColors.success),
        const SizedBox(height: 24),
        Text('Share Report', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _shareWhatsApp,
            icon: const Icon(Icons.share_outlined),
            label: const Text('Share to WhatsApp'),
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color)),
        trailing: Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
      ),
    );
  }
}