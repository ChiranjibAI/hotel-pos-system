import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/services/error_reporter.dart';

/// An in-app error log viewer that lists recent runtime errors captured by
/// [ErrorReporter]. This is the offline-first replacement for Firebase
/// Crashlytics — the owner can see what went wrong without a cloud account.
class ErrorLogPage extends StatefulWidget {
  const ErrorLogPage({super.key});

  @override
  State<ErrorLogPage> createState() => _ErrorLogPageState();
}

class _ErrorLogPageState extends State<ErrorLogPage> {
  @override
  void initState() {
    super.initState();
    ErrorReporter.instance.addListener(_onChange);
  }

  @override
  void dispose() {
    ErrorReporter.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final entries = ErrorReporter.instance.entries;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Log'),
        actions: [
          if (entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => ErrorReporter.instance.clear(),
              tooltip: 'Clear log',
            ),
        ],
      ),
      body: entries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 48, color: BrandColors.success.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'No errors recorded',
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'The app is running smoothly.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _ErrorCard(entry: entries[i]),
            ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final ErrorEntry entry;
  const _ErrorCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final timeStr = '${entry.time.hour.toString().padLeft(2, '0')}:'
        '${entry.time.minute.toString().padLeft(2, '0')}:'
        '${entry.time.second.toString().padLeft(2, '0')}';
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: Theme.of(context).cardTheme.color,
      collapsedBackgroundColor: Theme.of(context).cardTheme.color,
      leading: Icon(
        entry.fatal ? Icons.error_outline : Icons.warning_amber_outlined,
        color: entry.fatal ? BrandColors.danger : BrandColors.warning,
        size: 28,
      ),
      title: Text(
        entry.error,
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Text(timeStr, style: GoogleFonts.plusJakartaSans(fontSize: 11)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: BrandColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                entry.context,
                style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: BrandColors.gold),
              ),
            ),
            if (entry.fatal) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: BrandColors.danger.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'FATAL',
                  style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: BrandColors.danger),
                ),
              ),
            ],
          ],
        ),
      ),
      children: [
        if (entry.stack != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                entry.stack!,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace', height: 1.4),
                maxLines: 12,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }
}