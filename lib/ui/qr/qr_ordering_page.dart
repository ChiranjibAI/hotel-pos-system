import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/components/style/empty_body.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/models/repository/tables.dart';
import 'package:hotel_pos_system/models/restaurant/table.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// QR Code page — generates a scannable QR per table that links to a
/// digital menu (web URL). Customers scan the QR on their table to view
/// the menu and place an order from their phone.
///
/// The QR encodes a URL like: https://hotelpos.system/menu?table=T1
/// When cloud sync is enabled, this URL points to a live web menu that
/// pushes orders back to this POS. For now, the URL is configurable from
/// settings (default placeholder).
class QrOrderingPage extends StatefulWidget {
  const QrOrderingPage({super.key});

  @override
  State<QrOrderingPage> createState() => _QrOrderingPageState();
}

class _QrOrderingPageState extends State<QrOrderingPage> {
  String _baseUrl = 'https://hotelpos.system/menu';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Table Ordering'),
        actions: [
          IconButton(
            icon: const Icon(Icons.link_outlined),
            onPressed: _editBaseUrl,
            tooltip: 'Set menu URL',
          ),
        ],
      ),
      body: context.watch<Tables>().isEmpty
          ? const EmptyBody(
              title: 'No tables yet',
              content: 'Add tables first, then generate QR codes for each one.',
              icon: Icons.qr_code_outlined,
              onPressed: null,
            )
          : _buildGrid(context),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final tables = context.watch<Tables>().sorted;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemCount: tables.length,
      itemBuilder: (context, i) => _QrCard(
        table: tables[i],
        url: '$_baseUrl?table=${tables[i].name}',
      ),
    );
  }

  Future<void> _editBaseUrl() async {
    final ctrl = TextEditingController(text: _baseUrl);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Menu URL', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'https://your-menu-url.com',
            prefixIcon: Icon(Icons.link_outlined),
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _baseUrl = result);
    }
  }
}

class _QrCard extends StatelessWidget {
  final RestaurantTable table;
  final String url;
  const _QrCard({required this.table, required this.url});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showQrDialog(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              QrImageView(
                data: url,
                version: QrVersions.auto,
                size: 120,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(8),
              ),
              const SizedBox(height: 8),
              Text(
                table.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${table.seats} seats',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQrDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Table ${table.name}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Scan to view menu & order',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                QrImageView(
                  data: url,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  url,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: Colors.black45,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BrandColors.charcoal,
                      foregroundColor: BrandColors.gold,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}