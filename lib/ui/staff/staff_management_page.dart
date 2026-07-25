import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/components/style/empty_body.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/models/repository/staff.dart';
import 'package:hotel_pos_system/models/staff/staff.dart';
import 'package:provider/provider.dart';

/// Staff management page — add, edit, remove staff members and set their
/// roles + PINs. Only accessible to [StaffRole.owner].
class StaffManagementPage extends StatefulWidget {
  const StaffManagementPage({super.key});

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: _addStaff,
            tooltip: 'Add staff',
          ),
        ],
      ),
      body: context.watch<StaffRepository>().isEmpty
          ? const EmptyBody(
              title: 'No staff members',
              content: 'Add staff so they can log in with a PIN and access the POS by their role.',
              icon: Icons.people_outline,
              onPressed: null,
            )
          : _buildList(context),
    );
  }

  Widget _buildList(BuildContext context) {
    final staff = context.watch<StaffRepository>().itemList..sort();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: staff.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _StaffTile(staff: staff[i], onEdit: () => _editStaff(staff[i])),
    );
  }

  Future<void> _addStaff() => _showStaffDialog();

  Future<void> _editStaff(Staff staff) => _showStaffDialog(existing: staff);

  Future<void> _showStaffDialog({Staff? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final pinCtrl = TextEditingController(text: existing?.pin ?? '');
    StaffRole role = existing?.role ?? StaffRole.waiter;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(
            existing == null ? 'Add Staff Member' : 'Edit Staff',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pinCtrl,
                  decoration: const InputDecoration(
                    labelText: 'PIN (4-6 digits)',
                    prefixIcon: Icon(Icons.lock_outline),
                    counterText: '',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 12),
                // Role selector
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Role', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: StaffRole.values.map((r) {
                    final selected = r == role;
                    return FilterChip(
                      label: Text(_roleLabel(r)),
                      selected: selected,
                      onSelected: (_) => setDialog(() => role = r),
                      selectedColor: BrandColors.gold.withValues(alpha: 0.2),
                      checkmarkColor: BrandColors.gold,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || pinCtrl.text.length < 4) return;
                Navigator.of(context).pop(true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    final name = nameCtrl.text.trim();
    final pin = pinCtrl.text;
    if (existing == null) {
      final s = Staff(name: name, pin: pin, role: role);
      await StaffRepository.instance.addItem(s);
    } else {
      await existing.update(StaffObject(name: name, pin: pin, roleIndex: role.index));
      StaffRepository.instance.notifyItems();
    }
  }
}

class _StaffTile extends StatelessWidget {
  final Staff staff;
  final VoidCallback onEdit;
  const _StaffTile({required this.staff, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final config = _roleConfig(staff.role);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: config.color.withValues(alpha: 0.15),
          child: Text(
            staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: config.color),
          ),
        ),
        title: Text(staff.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: config.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                config.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: config.color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('PIN: ${'*' * staff.pin.length}', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: onEdit),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: BrandColors.danger),
              onPressed: () => _confirmDelete(context, staff),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Staff staff) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${staff.name}?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text('This staff member will no longer be able to log in.', style: GoogleFonts.plusJakartaSans()),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: BrandColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await staff.remove();
      StaffRepository.instance.notifyItems();
    }
  }
}

String _roleLabel(StaffRole r) => switch (r) {
  StaffRole.owner => 'Owner',
  StaffRole.manager => 'Manager',
  StaffRole.cashier => 'Cashier',
  StaffRole.waiter => 'Waiter',
};

_RoleConfig _roleConfig(StaffRole r) => switch (r) {
  StaffRole.owner => const _RoleConfig(label: 'Owner', color: BrandColors.gold),
  StaffRole.manager => const _RoleConfig(label: 'Manager', color: BrandColors.success),
  StaffRole.cashier => const _RoleConfig(label: 'Cashier', color: BrandColors.warning),
  StaffRole.waiter => const _RoleConfig(label: 'Waiter', color: BrandColors.goldBright),
};

class _RoleConfig {
  final String label;
  final Color color;
  const _RoleConfig({required this.label, required this.color});
}