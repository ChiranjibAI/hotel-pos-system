import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/models/objects/order_object.dart';

/// A dialog that renders a Kitchen Order Ticket (KOT) — a receipt for the
/// kitchen showing only item names and quantities, NO prices.
///
/// The kitchen only needs to know what to cook, not how much it costs. KOTs
/// are printed separately from the customer bill and are the standard way
/// restaurants communicate orders to the kitchen.
class KotDialog extends StatelessWidget {
  final OrderObject order;

  /// Optional table name to display on the KOT.
  final String? tableName;

  const KotDialog({super.key, required this.order, this.tableName});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _KotHeader(tableName: tableName, createdAt: order.createdAt),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              // Items list
              ...order.products.map((p) => _KotItem(
                    name: p.productName,
                    count: p.count,
                  )),
              // Attributes (e.g. "Dine-in", "No onions")
              if (order.attributes.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                ...order.attributes.map((a) => _KotAttribute(
                      name: a.optionName,
                      value: a.modeValue?.toString() ?? '',
                    )),
              ],
              if (order.note.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: BrandColors.gold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Note: ${order.note}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        // TODO: wire to printer — print KOT without prices
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'KOT sent to kitchen printer',
                              style: GoogleFonts.plusJakartaSans(),
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.print_rounded),
                      label: const Text('Print'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KotHeader extends StatelessWidget {
  final String? tableName;
  final DateTime createdAt;

  const _KotHeader({required this.tableName, required this.createdAt});

  @override
  Widget build(BuildContext context) {
    final time = '${createdAt.hour.toString().padLeft(2, '0')}:'
        '${createdAt.minute.toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: BrandColors.gold,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.restaurant_outlined, color: Colors.black87, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'KITCHEN ORDER',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            Text(
              time,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        if (tableName != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: BrandColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Table: $tableName',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: BrandColors.gold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _KotItem extends StatelessWidget {
  final String name;
  final int count;

  const _KotItem({required this.name, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: BrandColors.gold,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$count',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KotAttribute extends StatelessWidget {
  final String name;
  final String value;

  const _KotAttribute({required this.name, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            '$name: ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}