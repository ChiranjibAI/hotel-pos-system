import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/components/style/empty_body.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/models/repository/tables.dart';
import 'package:hotel_pos_system/models/restaurant/table.dart';
import 'package:hotel_pos_system/ui/tables/widgets/table_turn_badge.dart';
import 'package:provider/provider.dart';

/// Floor-plan view of all restaurant tables.
///
/// Tables are displayed in a responsive grid, color-coded by status:
/// green = available, red = occupied, amber = reserved, blue = cleaning.
/// Tapping a table opens an action sheet to change its status.
class TablesPage extends StatefulWidget {
  const TablesPage({super.key});

  @override
  State<TablesPage> createState() => _TablesPageState();
}

class _TablesPageState extends State<TablesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tables'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _addTable,
            tooltip: 'Add table',
          ),
        ],
      ),
      body: context.watch<Tables>().isEmpty
          ? EmptyBody(
              title: 'No tables yet',
              content: 'Add dining tables to manage your floor plan and link orders to them.',
              icon: Icons.table_restaurant_outlined,
              onPressed: _addTable,
            )
          : _buildGrid(context),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final tables = context.watch<Tables>().sorted;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 3 : 2);
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.1,
          ),
          itemCount: tables.length,
          itemBuilder: (context, i) => _TableCard(table: tables[i]),
        );
      },
    );
  }

  Future<void> _addTable() async {
    final name = await _showNameDialog();
    if (name == null || name.trim().isEmpty) return;

    final tables = Tables.instance;
    final count = tables.length;
    final cols = 3;
    final table = RestaurantTable(
      name: name.trim(),
      seats: 4,
      gridX: count % cols,
      gridY: count ~/ cols,
    );
    await tables.addItem(table);
  }

  Future<String?> _showNameDialog() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Table', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. T1, Window 5',
            prefixIcon: Icon(Icons.table_restaurant_outlined),
          ),
          onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

/// A single table card in the floor plan.
class _TableCard extends StatelessWidget {
  final RestaurantTable table;

  const _TableCard({required this.table});

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(table.tableStatus);
    return Material(
      color: config.bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showActions(context, table),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: config.accent, width: 1.5),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(config.icon, size: 36, color: config.accent),
              const SizedBox(height: 10),
              Text(
                table.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${table.seats} seats',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: config.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  config.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: config.accent,
                  ),
                ),
              ),
              TableTurnBadge(table: table),
            ],
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext context, RestaurantTable table) async {
    HapticFeedback.selectionClick();
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              table.name,
              style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              '${table.seats} seats • ${_statusConfig(table.tableStatus).label}',
              style: GoogleFonts.plusJakartaSans(color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 20),
            _ActionTile(
              icon: Icons.check_circle_outline,
              label: 'Mark Available',
              color: BrandColors.success,
              onTap: () => Navigator.of(context).pop('available'),
            ),
            _ActionTile(
              icon: Icons.restaurant_outlined,
              label: 'Mark Occupied',
              color: BrandColors.danger,
              onTap: () => Navigator.of(context).pop('occupied'),
            ),
            _ActionTile(
              icon: Icons.event_available_outlined,
              label: 'Mark Reserved',
              color: BrandColors.warning,
              onTap: () => Navigator.of(context).pop('reserved'),
            ),
            _ActionTile(
              icon: Icons.cleaning_services_outlined,
              label: 'Mark Cleaning',
              color: BrandColors.gold,
              onTap: () => Navigator.of(context).pop('cleaning'),
            ),
            const Divider(height: 24),
            _ActionTile(
              icon: Icons.delete_outline,
              label: 'Delete Table',
              color: BrandColors.danger,
              onTap: () => Navigator.of(context).pop('delete'),
            ),
          ],
        ),
      ),
    );

    if (action == null) return;

    switch (action) {
      case 'available':
        await Tables.instance.setStatus(table, TableStatus.available);
      case 'occupied':
        await Tables.instance.setStatus(table, TableStatus.occupied);
      case 'reserved':
        await Tables.instance.setStatus(table, TableStatus.reserved);
      case 'cleaning':
        await Tables.instance.setStatus(table, TableStatus.cleaning);
      case 'delete':
        await table.remove();
        Tables.instance.notifyItems();
    }
  }
}

/// Color/icon config per table status.
_StatusConfig _statusConfig(TableStatus s) {
  return switch (s) {
    TableStatus.available => _StatusConfig(
      icon: Icons.check_circle_outline,
      label: 'Available',
      accent: BrandColors.success,
      bg: BrandColors.success.withValues(alpha: 0.08),
    ),
    TableStatus.occupied => _StatusConfig(
      icon: Icons.restaurant_outlined,
      label: 'Occupied',
      accent: BrandColors.danger,
      bg: BrandColors.danger.withValues(alpha: 0.08),
    ),
    TableStatus.reserved => _StatusConfig(
      icon: Icons.event_available_outlined,
      label: 'Reserved',
      accent: BrandColors.warning,
      bg: BrandColors.warning.withValues(alpha: 0.08),
    ),
    TableStatus.cleaning => _StatusConfig(
      icon: Icons.cleaning_services_outlined,
      label: 'Cleaning',
      accent: BrandColors.gold,
      bg: BrandColors.gold.withValues(alpha: 0.08),
    ),
  };
}

class _StatusConfig {
  final IconData icon;
  final String label;
  final Color accent;
  final Color bg;
  const _StatusConfig({required this.icon, required this.label, required this.accent, required this.bg});
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}