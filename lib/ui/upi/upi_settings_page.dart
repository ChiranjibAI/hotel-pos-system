import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/services/cache.dart';

/// UPI settings page — configure the restaurant's UPI ID and payee name
/// so the UPI QR payment dialog can generate valid upi:// links.
class UpiSettingsPage extends StatefulWidget {
  const UpiSettingsPage({super.key});

  @override
  State<UpiSettingsPage> createState() => _UpiSettingsPageState();
}

class _UpiSettingsPageState extends State<UpiSettingsPage> {
  final _idCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _idCtrl.text = Cache.instance.get<String>('upi.id') ?? '';
    _nameCtrl.text = Cache.instance.get<String>('upi.name') ?? '';
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await Cache.instance.set<String>('upi.id', _idCtrl.text.trim());
    await Cache.instance.set<String>('upi.name', _nameCtrl.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('UPI settings saved'), behavior: SnackBarBehavior.floating),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UPI Payment Settings')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Accept payments via UPI with zero fees. Customers scan the QR and pay with PhonePe, GPay, Paytm, or any UPI app.',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color)),
            const SizedBox(height: 24),
            TextField(
              controller: _idCtrl,
              decoration: const InputDecoration(labelText: 'UPI ID', hintText: 'restaurant@upi', prefixIcon: Icon(Icons.account_balance_outlined)),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Payee Name (shows on customer app)', hintText: 'Spice Garden', prefixIcon: Icon(Icons.storefront_outlined)),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Save Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}