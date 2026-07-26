import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/models/restaurant/table.dart';
import 'package:hotel_pos_system/services/table_turn_predictor.dart';

/// Small badge shown on occupied table cards indicating the predicted
/// remaining dining time. Fetches asynchronously and caches per table.
class TableTurnBadge extends StatefulWidget {
  final RestaurantTable table;
  const TableTurnBadge({super.key, required this.table});

  @override
  State<TableTurnBadge> createState() => _TableTurnBadgeState();
}

class _TableTurnBadgeState extends State<TableTurnBadge> {
  int? _minutes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(TableTurnBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.table.id != widget.table.id ||
        oldWidget.table.tableStatus != widget.table.tableStatus) {
      _load();
    }
  }

  Future<void> _load() async {
    if (widget.table.tableStatus != TableStatus.occupied) {
      if (mounted) setState(() { _minutes = null; _loading = false; });
      return;
    }
    final mins = await TableTurnPredictor.instance.predictRemaining(widget.table);
    if (mounted) {
      setState(() { _minutes = mins; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.table.tableStatus != TableStatus.occupied) {
      return const SizedBox.shrink();
    }
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: BrandColors.gold.withValues(alpha: 0.5),
          ),
        ),
      );
    }
    final mins = _minutes;
    if (mins == null) return const SizedBox.shrink();

    final config = _badgeConfig(mins);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
    );
  }
}

_BadgeConfig _badgeConfig(int remainingMinutes) {
  if (remainingMinutes <= 0) {
    return _BadgeConfig(label: 'Overdue', color: BrandColors.danger);
  }
  if (remainingMinutes <= 15) {
    return _BadgeConfig(label: 'Soon ~${remainingMinutes}m', color: BrandColors.warning);
  }
  return _BadgeConfig(label: 'ETA ${remainingMinutes}m', color: BrandColors.success);
}

class _BadgeConfig {
  final String label;
  final Color color;
  const _BadgeConfig({required this.label, required this.color});
}