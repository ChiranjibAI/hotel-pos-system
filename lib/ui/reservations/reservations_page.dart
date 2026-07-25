import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/components/style/empty_body.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/models/repository/reservations.dart';
import 'package:hotel_pos_system/models/reservation/reservation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ReservationsPage extends StatefulWidget {
  const ReservationsPage({super.key});

  @override
  State<ReservationsPage> createState() => _ReservationsPageState();
}

class _ReservationsPageState extends State<ReservationsPage> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservations'),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_today_outlined), onPressed: _pickDate, tooltip: 'Pick date'),
          IconButton(icon: const Icon(Icons.add_rounded), onPressed: _addReservation, tooltip: 'Add reservation'),
        ],
      ),
      body: Column(
        children: [
          // Date header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(DateFormat.yMMMd().format(_selectedDate),
                    style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                TextButton(onPressed: () => setState(() => _selectedDate = DateTime.now()), child: const Text('Today')),
              ],
            ),
          ),
          Expanded(child: _buildList(context)),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final reservations = context.watch<ReservationsRepository>().forDate(_selectedDate);
    if (reservations.isEmpty) {
      return EmptyBody(
        title: 'No reservations',
        content: 'No reservations for ${DateFormat.yMMMd().format(_selectedDate)}. Tap + to add one.',
        icon: Icons.event_available_outlined,
        onPressed: _addReservation,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: reservations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _ReservationCard(
        reservation: reservations[i],
        onEdit: () => _editReservation(reservations[i]),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _addReservation() => _showDialog();

  Future<void> _editReservation(Reservation r) => _showDialog(existing: r);

  Future<void> _showDialog({Reservation? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.customerPhone ?? '');
    final sizeCtrl = TextEditingController(text: '${existing?.partySize ?? 2}');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    DateTime pickedDate = existing?.dateTime ?? DateTime.now().add(const Duration(hours: 2));
    TimeOfDay pickedTime = TimeOfDay.fromDateTime(pickedDate);
    ReservationStatus status = existing?.reservationStatus ?? ReservationStatus.pending;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(existing == null ? 'New Reservation' : 'Edit Reservation',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Customer name', prefixIcon: Icon(Icons.person_outline)), textCapitalization: TextCapitalization.words),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)), keyboardType: TextInputType.phone),
                const SizedBox(height: 10),
                TextField(controller: sizeCtrl, decoration: const InputDecoration(labelText: 'Party size', prefixIcon: Icon(Icons.group_outlined)), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                const SizedBox(height: 10),
                // Date + time pickers
                Row(
                  children: [
                    Expanded(child: TextButton.icon(
                      icon: const Icon(Icons.calendar_today_outlined), label: Text(DateFormat.yMMMd().format(pickedDate)),
                      onPressed: () async {
                        final d = await showDatePicker(context: context, initialDate: pickedDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
                        if (d != null) setDialog(() => pickedDate = d);
                      },
                    )),
                    Expanded(child: TextButton.icon(
                      icon: const Icon(Icons.access_time_outlined), label: Text(pickedTime.format(context)),
                      onPressed: () async {
                        final t = await showTimePicker(context: context, initialTime: pickedTime);
                        if (t != null) setDialog(() => pickedTime = t);
                      },
                    )),
                  ],
                ),
                const SizedBox(height: 10),
                // Status chips
                Wrap(
                  spacing: 6,
                  children: ReservationStatus.values.map((s) {
                    final selected = s == status;
                    return FilterChip(
                      label: Text(_statusLabel(s)),
                      selected: selected,
                      onSelected: (_) => setDialog(() => status = s as ReservationStatus),
                      selectedColor: BrandColors.gold.withValues(alpha: 0.2),
                      checkmarkColor: BrandColors.gold,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)', prefixIcon: Icon(Icons.note_outlined)), maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (saved != true) return;
    final dateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
    if (existing == null) {
      await ReservationsRepository.instance.addItem(Reservation(
        name: nameCtrl.text.trim(),
        customerPhone: phoneCtrl.text.trim(),
        dateTime: dateTime,
        partySize: int.tryParse(sizeCtrl.text) ?? 2,
        reservationStatus: status,
        notes: notesCtrl.text.trim(),
      ));
    } else {
      await existing.update(ReservationObject(
        customerName: nameCtrl.text.trim(),
        customerPhone: phoneCtrl.text.trim(),
        timestamp: dateTime.millisecondsSinceEpoch,
        partySize: int.tryParse(sizeCtrl.text) ?? 2,
        statusIndex: (status as ReservationStatus).index,
        notes: notesCtrl.text.trim(),
      ));
      ReservationsRepository.instance.notifyItems();
    }
  }
}

class _ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback onEdit;
  const _ReservationCard({required this.reservation, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(reservation.reservationStatus);
    final timeStr = '${reservation.dateTime.hour.toString().padLeft(2, '0')}:${reservation.dateTime.minute.toString().padLeft(2, '0')}';
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: config.color.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: config.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(timeStr, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: config.color)),
            Text('${reservation.partySize}p', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: config.color)),
          ]),
        ),
        title: Text(reservation.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        subtitle: Text(reservation.customerPhone, style: GoogleFonts.plusJakartaSans(fontSize: 12)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: config.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
            child: Text(config.label, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: config.color)),
          ),
          IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: onEdit),
        ]),
      ),
    );
  }
}

String _statusLabel(ReservationStatus s) => switch (s) {
  ReservationStatus.pending => 'Pending',
  ReservationStatus.confirmed => 'Confirmed',
  ReservationStatus.seated => 'Seated',
  ReservationStatus.cancelled => 'Cancelled',
  ReservationStatus.noShow => 'No Show',
};

_StatusConfig _statusConfig(ReservationStatus s) => switch (s) {
  ReservationStatus.pending => const _StatusConfig(label: 'Pending', color: BrandColors.warning),
  ReservationStatus.confirmed => const _StatusConfig(label: 'Confirmed', color: BrandColors.success),
  ReservationStatus.seated => const _StatusConfig(label: 'Seated', color: BrandColors.gold),
  ReservationStatus.cancelled => const _StatusConfig(label: 'Cancelled', color: BrandColors.danger),
  ReservationStatus.noShow => const _StatusConfig(label: 'No Show', color: BrandColors.danger),
};

class _StatusConfig {
  final String label;
  final Color color;
  const _StatusConfig({required this.label, required this.color});
}