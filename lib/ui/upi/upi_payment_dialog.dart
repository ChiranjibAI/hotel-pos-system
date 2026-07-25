import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/services/cache.dart';

/// UPI QR Payment dialog — generates a dynamic UPI QR for the customer to
/// scan and pay with any UPI app (PhonePe, GPay, Paytm). No payment gateway,
/// zero transaction fees.
///
/// The UPI ID is configurable (Settings). Format:
/// upi://pay?pa=<upi_id>&pn=<name>&am=<amount>&cu=INR&tn=<note>
class UpiPaymentDialog extends StatefulWidget {
  final num amount;
  final String? orderNote;

  const UpiPaymentDialog({super.key, required this.amount, this.orderNote});

  @override
  State<UpiPaymentDialog> createState() => _UpiPaymentDialogState();
}

class _UpiPaymentDialogState extends State<UpiPaymentDialog> {
  String get _upiId => Cache.instance.get<String>('upi.id') ?? '';
  String get _payeeName => Cache.instance.get<String>('upi.name') ?? 'Hotel POS';
  String get _upiString {
    final note = widget.orderNote != null ? '&tn=${Uri.encodeComponent(widget.orderNote!)}' : '';
    return 'upi://pay?pa=$_upiId&pn=${Uri.encodeComponent(_payeeName)}&am=${widget.amount.toStringAsFixed(2)}&cu=INR$note';
  }

  @override
  Widget build(BuildContext context) {
    if (_upiId.isEmpty) {
      return _setupPrompt(context);
    }
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pay via UPI', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87)),
              const SizedBox(height: 4),
              Text('Scan with any UPI app', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(color: BrandColors.charcoal, borderRadius: BorderRadius.circular(10)),
                child: Text('Amount: ₹${widget.amount.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: BrandColors.gold)),
              ),
              const SizedBox(height: 20),
              QrImageView(data: _upiString, version: QrVersions.auto, size: 220, backgroundColor: Colors.white),
              const SizedBox(height: 16),
              Text('UPI ID: $_upiId', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 8),
              Text(_payeeName, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: BrandColors.charcoal, foregroundColor: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _setupPrompt(BuildContext context) {
    return AlertDialog(
      title: Text('UPI Not Configured', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
      content: Text('Set your UPI ID in Settings > UPI Payment to accept UPI payments.', style: GoogleFonts.plusJakartaSans()),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
      ],
    );
  }
}