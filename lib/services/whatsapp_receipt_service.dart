import 'package:hotel_pos_system/models/objects/order_object.dart';
import 'package:hotel_pos_system/helpers/logger.dart';
import 'package:url_launcher/url_launcher.dart';

/// WhatsApp receipt service — sends a receipt as a WhatsApp message via
/// the wa.me link (opens WhatsApp with pre-filled text, no API needed).
///
/// Uses url_launcher to open: https://wa.me/<phone>?text=<receipt_text>
class WhatsAppReceiptService {
  static WhatsAppReceiptService instance = WhatsAppReceiptService();

  WhatsAppReceiptService();

  /// Build a plain-text receipt from an order object (no special chars that
  /// WhatsApp can't handle).
  String buildReceiptText(OrderObject order, {String? restaurantName}) {
    final lines = <String>[];
    lines.add('*${restaurantName ?? 'Hotel POS System'}*');
    lines.add('Receipt #${order.id ?? order.createdAt.millisecondsSinceEpoch}');
    lines.add('${_formatDate(order.createdAt)}');
    lines.add('------------------------');
    for (final p in order.products) {
      lines.add('${p.count}x ${p.productName}  \$${p.totalPrice.toStringAsFixed(2)}');
    }
    lines.add('------------------------');
    lines.add('Total: *\$${order.price.toStringAsFixed(2)}*');
    if (order.paid > 0 && order.paid != order.price) {
      lines.add('Paid: \$${order.paid.toStringAsFixed(2)}');
      lines.add('Change: \$${(order.paid - order.price).toStringAsFixed(2)}');
    }
    if (order.note.isNotEmpty) {
      lines.add('Note: ${order.note}');
    }
    lines.add('------------------------');
    lines.add('Thank you! Visit again.');
    return lines.join('\n');
  }

  /// Send a receipt via WhatsApp. [phone] should be in international format
  /// without + (e.g. 919876543210 for India). If phone is null/empty, opens
  /// WhatsApp with the text but no recipient (user picks a contact).
  Future<bool> sendReceipt(OrderObject order, {String? phone, String? restaurantName}) async {
    final text = buildReceiptText(order, restaurantName: restaurantName);
    final encodedText = Uri.encodeComponent(text);
    final url = phone != null && phone.isNotEmpty
        ? 'https://wa.me/$phone?text=$encodedText'
        : 'https://wa.me/?text=$encodedText';

    try {
      final uri = Uri.parse(url);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      Log.err(e, 'whatsapp_send', null);
      return false;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}