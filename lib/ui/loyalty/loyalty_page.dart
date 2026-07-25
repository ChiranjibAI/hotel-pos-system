import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/components/style/empty_body.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/models/customer/customer.dart';
import 'package:hotel_pos_system/models/repository/customers.dart';
import 'package:provider/provider.dart';

/// Loyalty program page — manage customers, view points, add/remove customers.
class LoyaltyPage extends StatefulWidget {
  const LoyaltyPage({super.key});

  @override
  State<LoyaltyPage> createState() => _LoyaltyPageState();
}

class _LoyaltyPageState extends State<LoyaltyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loyalty Program'),
        actions: [
          IconButton(icon: const Icon(Icons.person_add_outlined), onPressed: _addCustomer, tooltip: 'Add customer'),
        ],
      ),
      body: context.watch<Customers>().isEmpty
          ? const EmptyBody(
              title: 'No customers yet',
              content: 'Add customers with their phone number to track loyalty points.',
              icon: Icons.card_giftcard_outlined,
              onPressed: null,
            )
          : _buildList(context),
    );
  }

  Widget _buildList(BuildContext context) {
    final customers = context.watch<Customers>().itemList..sort();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: customers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _CustomerTile(
        customer: customers[i],
        onEdit: () => _editCustomer(customers[i]),
      ),
    );
  }

  Future<void> _addCustomer() => _showDialog();

  Future<void> _editCustomer(Customer c) => _showDialog(existing: c);

  Future<void> _showDialog({Customer? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final pointsCtrl = TextEditingController(text: existing?.points.toString() ?? '0');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add Customer' : 'Edit Customer',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outline)), textCapitalization: TextCapitalization.words),
            const SizedBox(height: 12),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)), keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            TextField(controller: pointsCtrl, decoration: const InputDecoration(labelText: 'Points', prefixIcon: Icon(Icons.stars_outlined)), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Save')),
        ],
      ),
    );

    if (saved != true) return;
    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final points = num.tryParse(pointsCtrl.text) ?? 0;
    if (name.isEmpty || phone.isEmpty) return;

    if (existing == null) {
      await Customers.instance.addItem(Customer(name: name, phone: phone, points: points));
    } else {
      await existing.update(CustomerObject(name: name, phone: phone, points: points, totalSpent: existing.totalSpent, orderCount: existing.orderCount));
      Customers.instance.notifyItems();
    }
  }
}

class _CustomerTile extends StatelessWidget {
  final Customer customer;
  final VoidCallback onEdit;
  const _CustomerTile({required this.customer, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: BrandColors.gold.withValues(alpha: 0.15),
          child: const Icon(Icons.person, color: BrandColors.gold),
        ),
        title: Text(customer.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        subtitle: Text(customer.phone, style: GoogleFonts.plusJakartaSans(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Points badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: BrandColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${customer.points} pts',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: BrandColors.gold),
              ),
            ),
            IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: onEdit),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: BrandColors.danger),
              onPressed: () async {
                await customer.remove();
                Customers.instance.notifyItems();
              },
            ),
          ],
        ),
      ),
    );
  }
}