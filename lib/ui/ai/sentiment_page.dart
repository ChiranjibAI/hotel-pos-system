import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/components/style/empty_body.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/services/sentiment_service.dart';

/// Sentiment Analysis page — shows feedback sentiment breakdown
/// and lets the owner add new feedback for analysis.
class SentimentPage extends StatefulWidget {
  const SentimentPage({super.key});

  @override
  State<SentimentPage> createState() => _SentimentPageState();
}

class _SentimentPageState extends State<SentimentPage> {
  final _textCtrl = TextEditingController();
  int _rating = 3;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _addFeedback() {
    if (_textCtrl.text.trim().isEmpty) return;
    SentimentService.instance.addFeedback(_textCtrl.text.trim(), rating: _rating);
    _textCtrl.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final service = SentimentService.instance;
    final summary = service.summary;
    final total = service.feedback.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Sentiment Analysis')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Add feedback
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add Feedback', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: BrandColors.gold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _textCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Paste customer feedback or review...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Rating: ', style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                      for (var i = 1; i <= 5; i++)
                        IconButton(
                          icon: Icon(i <= _rating ? Icons.star : Icons.star_border,
                              color: BrandColors.gold, size: 20),
                          onPressed: () => setState(() => _rating = i),
                        ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _addFeedback,
                        icon: const Icon(Icons.add),
                        label: Text('Analyze', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (total == 0)
            EmptyBody(
              title: 'No feedback yet',
              content: 'Add customer feedback above to see sentiment analysis.',
              icon: Icons.sentiment_satisfied_outlined,
              onPressed: () {},
            )
          else ...[
            // Summary
            Text('SUMMARY', style: GoogleFonts.plusJakartaSans(
              fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: BrandColors.gold,
            )),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildSummaryCard('Positive', summary[SentimentCategory.positive] ?? 0, total, BrandColors.success),
                const SizedBox(width: 8),
                _buildSummaryCard('Neutral', summary[SentimentCategory.neutral] ?? 0, total, BrandColors.warning),
                const SizedBox(width: 8),
                _buildSummaryCard('Negative', summary[SentimentCategory.negative] ?? 0, total, BrandColors.danger),
              ],
            ),
            const SizedBox(height: 20),
            Text('RECENT FEEDBACK', style: GoogleFonts.plusJakartaSans(
              fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: BrandColors.gold,
            )),
            const SizedBox(height: 12),
            ...service.feedback.reversed.map((f) => _buildFeedbackCard(f)),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, int count, int total, Color color) {
    final pct = total > 0 ? (count / total * 100).round() : 0;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text('$pct%', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
              Text('$count', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
              Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(FeedbackEntry entry) {
    final config = _sentimentConfig(entry.sentiment.category);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(config.icon, color: config.color, size: 18),
                const SizedBox(width: 8),
                Text('${'★' * entry.rating}${'☆' * (5 - entry.rating)}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: BrandColors.gold)),
                const Spacer(),
                Text(config.label, style: GoogleFonts.plusJakartaSans(
                  fontSize: 10, fontWeight: FontWeight.w700, color: config.color,
                )),
              ],
            ),
            const SizedBox(height: 8),
            Text(entry.text, style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.4)),
            if (entry.sentiment.aspects.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: entry.sentiment.aspects.map((a) => Chip(
                  label: Text(a, style: GoogleFonts.plusJakartaSans(fontSize: 10)),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

_SentimentConfig _sentimentConfig(SentimentCategory c) {
  return switch (c) {
    SentimentCategory.positive => _SentimentConfig(
      icon: Icons.sentiment_very_satisfied_outlined, label: 'POSITIVE', color: BrandColors.success,
    ),
    SentimentCategory.neutral => _SentimentConfig(
      icon: Icons.sentiment_neutral_outlined, label: 'NEUTRAL', color: BrandColors.warning,
    ),
    SentimentCategory.negative => _SentimentConfig(
      icon: Icons.sentiment_dissatisfied_outlined, label: 'NEGATIVE', color: BrandColors.danger,
    ),
  };
}

class _SentimentConfig {
  final IconData icon;
  final String label;
  final Color color;
  const _SentimentConfig({required this.icon, required this.label, required this.color});
}