import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/models/repository/seller.dart';
import 'package:hotel_pos_system/settings/currency_setting.dart';

/// A row of KPI summary cards shown at the top of the analysis dashboard.
///
/// Displays today's revenue, order count, and average order value in three
/// premium-styled cards with icons and a subtle gold accent. Data is loaded
/// asynchronously from [Seller.getMetrics] for today's date range.
class KpiDashboard extends StatefulWidget {
  const KpiDashboard({super.key});

  @override
  State<KpiDashboard> createState() => _KpiDashboardState();
}

class _KpiDashboardState extends State<KpiDashboard> {
  OrderMetrics? _metrics;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 1));
      final metrics = await Seller.instance.getMetrics(start, end);
      if (mounted) {
        setState(() {
          _metrics = metrics;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(child: _KpiSkeleton()),
            SizedBox(width: 10),
            Expanded(child: _KpiSkeleton()),
            SizedBox(width: 10),
            Expanded(child: _KpiSkeleton()),
          ],
        ),
      );
    }

    final m = _metrics;
    final revenue = m?.revenue ?? 0;
    final count = m?.count ?? 0;
    final avg = count > 0 ? revenue / count : 0.0;

    final fmt = CurrencySetting.instance.formatter;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _KpiCard(
              icon: Icons.payments_rounded,
              label: 'Today\'s Revenue',
              value: _formatMoney(revenue, fmt),
              color: BrandColors.gold,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _KpiCard(
              icon: Icons.receipt_long_rounded,
              label: 'Orders',
              value: count.toString(),
              color: BrandColors.success,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _KpiCard(
              icon: Icons.trending_up_rounded,
              label: 'Avg Order',
              value: _formatMoney(avg, fmt),
              color: BrandColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMoney(num value, dynamic fmt) {
    if (value == 0) return '0';
    try {
      return fmt.format(value);
    } catch (_) {
      return value.toStringAsFixed(0);
    }
  }
}

/// A single KPI card with icon, label, and value.
class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? BrandColors.charcoalCard : BrandColors.creamCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : BrandColors.creamBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// A shimmer-like placeholder while KPI data loads.
class _KpiSkeleton extends StatelessWidget {
  const _KpiSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: isDark ? BrandColors.charcoalCard : BrandColors.creamCard,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}