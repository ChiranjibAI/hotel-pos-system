import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/components/style/empty_body.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/services/churn_predictor.dart';
import 'package:url_launcher/url_launcher.dart';

/// Churn Prediction page — shows customers at risk of churning,
/// sorted by risk tier. Tap to send a win-back WhatsApp offer.
class ChurnPage extends StatefulWidget {
  const ChurnPage({super.key});

  @override
  State<ChurnPage> createState() => _ChurnPageState();
}

class _ChurnPageState extends State<ChurnPage> {
  List<ChurnRisk> _risks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final r = ChurnPredictor.instance.predict();
    setState(() { _risks = r; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Churn Prediction'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_outlined)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _risks.isEmpty
              ? EmptyBody(
                  title: 'No loyalty customers yet',
                  content: 'Add customers to your loyalty program to see churn predictions.',
                  icon: Icons.people_outline,
                  onPressed: _load,
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final critical = _risks.where((r) => r.tier == ChurnTier.critical).length;
    final atRisk = _risks.where((r) => r.tier == ChurnTier.atRisk).length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _stat('Critical', '$critical', BrandColors.danger),
                _stat('At Risk', '$atRisk', BrandColors.warning),
                _stat('Total', '${_risks.length}', BrandColors.gold),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ..._risks.map((r) => _buildRiskCard(r)),
      ],
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
      ],
    );
  }

  Widget _buildRiskCard(ChurnRisk risk) {
    final config = _tierConfig(risk.tier);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: config.color.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: config.color.withValues(alpha: 0.12),
          child: Text(risk.name.isNotEmpty ? risk.name[0].toUpperCase() : '?',
              style: GoogleFonts.plusJakartaSans(color: config.color, fontWeight: FontWeight.w800)),
        ),
        title: Text(risk.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${risk.orderCount} orders • ₹${risk.totalSpent.toStringAsFixed(0)} spent',
                style: GoogleFonts.plusJakartaSans(fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: risk.score,
                      color: config.color,
                      backgroundColor: config.color.withValues(alpha: 0.1),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(config.label, style: GoogleFonts.plusJakartaSans(
                  fontSize: 10, fontWeight: FontWeight.w700, color: config.color,
                )),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.send_rounded, color: BrandColors.success),
          onPressed: () => _sendWinback(risk),
        ),
        onTap: () => _sendWinback(risk),
      ),
    );
  }

  Future<void> _sendWinback(ChurnRisk risk) async {
    final msg = 'Hi ${risk.name}! We miss you at our restaurant. '
        'Come back this week and enjoy 15% off your favorite meal. '
        'Show this message to claim your discount. Reply to order.';
    final cleanPhone = risk.phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No phone number for ${risk.name}', style: GoogleFonts.plusJakartaSans())),
      );
      return;
    }
    final url = 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(msg)}';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

_TierConfig _tierConfig(ChurnTier tier) {
  return switch (tier) {
    ChurnTier.critical => _TierConfig(label: 'CRITICAL', color: BrandColors.danger),
    ChurnTier.atRisk => _TierConfig(label: 'AT RISK', color: BrandColors.warning),
    ChurnTier.stable => _TierConfig(label: 'STABLE', color: BrandColors.success),
  };
}

class _TierConfig {
  final String label;
  final Color color;
  const _TierConfig({required this.label, required this.color});
}