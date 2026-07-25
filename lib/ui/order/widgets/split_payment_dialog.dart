import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';

/// A split-payment dialog that lets the customer pay the bill across multiple
/// payment methods (Cash, Card, UPI) and add an optional tip.
///
/// Shows the total, lets you add payment lines, tracks the remaining balance,
/// and calculates change for cash. The result is returned as a [SplitPayment]
/// record when the bill is fully covered.
class SplitPaymentDialog extends StatefulWidget {
  final num total;

  const SplitPaymentDialog({super.key, required this.total});

  @override
  State<SplitPaymentDialog> createState() => _SplitPaymentDialogState();

  /// Show the dialog and return the [SplitPayment] result, or null if cancelled.
  static Future<SplitPayment?> show(BuildContext context, {required num total}) {
    return showDialog<SplitPayment>(
      context: context,
      builder: (context) => SplitPaymentDialog(total: total),
    );
  }
}

class _SplitPaymentDialogState extends State<SplitPaymentDialog> {
  final List<PaymentLine> _lines = [];
  num _tip = 0;
  PaymentMethod _method = PaymentMethod.cash;

  num get _paid => _lines.fold<num>(0, (sum, l) => sum + l.amount) + _tip;
  num get _grandTotal => widget.total + _tip;
  num get _remaining => _grandTotal - _paid;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Split Payment',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total: ${_fmt(widget.total)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 16),
                // Tip input
                _TipRow(
                  value: _tip,
                  onChanged: (v) => setState(() => _tip = v),
                ),
                const SizedBox(height: 16),
                // Payment method selector
                Text('Payment Method', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _MethodSelector(
                  selected: _method,
                  onChanged: (m) => setState(() => _method = m),
                ),
                const SizedBox(height: 16),
                // Add payment
                _AddPaymentRow(
                  method: _method,
                  remaining: _remaining > 0 ? _remaining : 0,
                  onAdd: (amount) => setState(() {
                    _lines.add(PaymentLine(method: _method, amount: amount));
                    HapticFeedback.lightImpact();
                  }),
                ),
                const SizedBox(height: 16),
                // Payment lines list
                if (_lines.isNotEmpty) ...[
                  ..._lines.asMap().entries.map((e) => _PaymentLineTile(
                        line: e.value,
                        index: e.key,
                        onRemove: () => setState(() => _lines.removeAt(e.key)),
                      )),
                  const Divider(height: 20),
                ],
                // Summary
                _SummaryRow(label: 'Tip', value: _fmt(_tip)),
                _SummaryRow(label: 'Total Paid', value: _fmt(_paid)),
                _SummaryRow(
                  label: 'Remaining',
                  value: _fmt(_remaining),
                  highlight: _remaining.abs() > 0.01,
                ),
                const SizedBox(height: 20),
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _remaining.abs() < 0.01 && _paid > 0
                            ? () {
                                HapticFeedback.mediumImpact();
                                Navigator.of(context).pop(SplitPayment(
                                  lines: _lines,
                                  tip: _tip,
                                  total: _grandTotal,
                                ));
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _remaining.abs() < 0.01 ? BrandColors.success : null,
                        ),
                        child: const Text('Confirm'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(num v) => '\$${v.toStringAsFixed(2)}';
}

/// A single payment line (method + amount).
class PaymentLine {
  final PaymentMethod method;
  final num amount;
  const PaymentLine({required this.method, required this.amount});
}

/// The full split-payment result.
class SplitPayment {
  final List<PaymentLine> lines;
  final num tip;
  final num total;
  const SplitPayment({required this.lines, required this.tip, required this.total});

  num get paid => lines.fold<num>(0, (sum, l) => sum + l.amount) + tip;
  num get change => paid - total;
}

enum PaymentMethod { cash, card, upi }

class _TipRow extends StatelessWidget {
  final num value;
  final ValueChanged<num> onChanged;
  const _TipRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Tip', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: '0.00', prefixIcon: Icon(Icons.volunteer_activism_outlined)),
            onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
          ),
        ),
      ],
    );
  }
}

class _MethodSelector extends StatelessWidget {
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;
  const _MethodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<PaymentMethod>(
      segments: const [
        ButtonSegment(value: PaymentMethod.cash, icon: Icon(Icons.payments_outlined), label: Text('Cash')),
        ButtonSegment(value: PaymentMethod.card, icon: Icon(Icons.credit_card_outlined), label: Text('Card')),
        ButtonSegment(value: PaymentMethod.upi, icon: Icon(Icons.qr_code_outlined), label: Text('UPI')),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _AddPaymentRow extends StatefulWidget {
  final PaymentMethod method;
  final num remaining;
  final ValueChanged<num> onAdd;
  const _AddPaymentRow({required this.method, required this.remaining, required this.onAdd});

  @override
  State<_AddPaymentRow> createState() => _AddPaymentRowState();
}

class _AddPaymentRowState extends State<_AddPaymentRow> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: widget.remaining.toStringAsFixed(2),
              prefixIcon: const Icon(Icons.add_rounded),
            ),
            onSubmitted: _add,
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () => _add(_controller.text),
          child: const Text('Add'),
        ),
      ],
    );
  }

  void _add(String value) {
    final amount = double.tryParse(value) ?? 0;
    if (amount > 0) {
      widget.onAdd(amount);
      _controller.clear();
    }
  }
}

class _PaymentLineTile extends StatelessWidget {
  final PaymentLine line;
  final int index;
  final VoidCallback onRemove;
  const _PaymentLineTile({required this.line, required this.index, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final icon = switch (line.method) {
      PaymentMethod.cash => Icons.payments_outlined,
      PaymentMethod.card => Icons.credit_card_outlined,
      PaymentMethod.upi => Icons.qr_code_outlined,
    };
    final label = switch (line.method) {
      PaymentMethod.cash => 'Cash',
      PaymentMethod.card => 'Card',
      PaymentMethod.upi => 'UPI',
    };
    return ListTile(
      leading: Icon(icon, color: BrandColors.gold),
      title: Text(label, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('\$${line.amount.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: onRemove),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _SummaryRow({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              color: highlight ? BrandColors.danger : null,
            ),
          ),
        ],
      ),
    );
  }
}