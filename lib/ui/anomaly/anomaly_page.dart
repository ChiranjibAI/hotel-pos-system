import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/components/style/empty_body.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/services/anomaly_detector.dart';

/// Anomaly / Fraud Detection page.
///
/// Scans order history (last 30 days by default) and shows alerts
/// for suspicious patterns: repeated billing amounts, after-hours
/// activity, excessive discounts. Pure Dart, no LLM needed.
class AnomalyPage extends StatefulWidget {
  const AnomalyPage({super.key});

  @override
  State<AnomalyPage> createState() => _AnomalyPageState();
}

class _AnomalyPageState extends State<AnomalyPage> {
  List<AnomalyAlert> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final alerts = await AnomalyDetector.instance.detect();
    if (mounted) {
      setState(() {
        _alerts = alerts;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anomaly Detection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _load,
            tooltip: 'Re-scan',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _alerts.isEmpty
              ? EmptyBody(
                  title: 'No anomalies detected',
                  content:
                      'Scanned the last 30 days of orders. Everything looks clean.',
                  icon: Icons.verified_user_outlined,
                  onPressed: _load,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: _alerts.length,
                    itemBuilder: (context, i) =>
                        _AlertCard(alert: _alerts[i]),
                  ),
                ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AnomalyAlert alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final config = _severityConfig(alert.severity);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: config.color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: config.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(config.icon, color: config.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: config.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          config.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: config.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

_SeverityConfig _severityConfig(AnomalySeverity s) {
  return switch (s) {
    AnomalySeverity.high => _SeverityConfig(
      icon: Icons.error_outline,
      label: 'HIGH',
      color: BrandColors.danger,
    ),
    AnomalySeverity.medium => _SeverityConfig(
      icon: Icons.warning_amber_outlined,
      label: 'MEDIUM',
      color: BrandColors.warning,
    ),
    AnomalySeverity.low => _SeverityConfig(
      icon: Icons.info_outline,
      label: 'LOW',
      color: BrandColors.gold,
    ),
  };
}

class _SeverityConfig {
  final IconData icon;
  final String label;
  final Color color;
  const _SeverityConfig({
    required this.icon,
    required this.label,
    required this.color,
  });
}