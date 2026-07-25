import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/models/menu/product.dart';
import 'package:hotel_pos_system/models/repository/cart.dart';
import 'package:hotel_pos_system/models/repository/menu.dart';

/// Voice Ordering page — the waiter speaks the order, the app parses it
/// and matches items from the menu by name keywords. Quantities are
/// extracted from numbers in the spoken text ("two", "2", "three").
///
/// This is a simplified offline parser — no speech-to-text SDK dependency.
/// The waiter types or pastes the spoken text, and the app parses it.
/// To add real speech recognition, integrate flutter's speech_to_text plugin
/// and feed the transcript into _parseOrder().
class VoiceOrderingPage extends StatefulWidget {
  const VoiceOrderingPage({super.key});

  @override
  State<VoiceOrderingPage> createState() => _VoiceOrderingPageState();
}

class _VoiceOrderingPageState extends State<VoiceOrderingPage> {
  final _textCtrl = TextEditingController();
  List<_ParsedItem> _parsed = [];
  bool _added = false;

  static const _numberWords = {
    'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
    'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
    '1': 1, '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9, '10': 10,
  };

  void _parseOrder() {
    final text = _textCtrl.text.trim().toLowerCase();
    if (text.isEmpty) return;

    final products = Menu.instance.products.toList();
    final words = text.split(RegExp(r'[,;\n]|\band\b'));
    final results = <_ParsedItem>[];

    for (var segment in words) {
      segment = segment.trim();
      if (segment.isEmpty) continue;

      // Extract quantity from leading number/word
      int qty = 1;
      final segments = segment.split(' ');
      if (segments.isNotEmpty && _numberWords.containsKey(segments[0])) {
        qty = _numberWords[segments[0]]!;
        segment = segments.sublist(1).join(' ');
      }

      if (segment.isEmpty) continue;

      // Match against product names (fuzzy: contains keyword)
      Product? match;
      for (final p in products) {
        final name = p.name.toLowerCase();
        if (name.contains(segment) || segment.contains(name)) {
          match = p;
          break;
        }
      }

      if (match != null) {
        results.add(_ParsedItem(product: match, quantity: qty));
      }
    }

    setState(() { _parsed = results; _added = false; });
  }

  Future<void> _addToCart() async {
    for (final item in _parsed) {
      for (var i = 0; i < item.quantity; i++) {
        Cart.instance.add(item.product);
      }
    }
    HapticFeedback.mediumImpact();
    setState(() => _added = true);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Ordering')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: BrandColors.gold.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.mic_outlined, size: 36, color: BrandColors.gold),
                  const SizedBox(height: 8),
                  Text('Enter the spoken order', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _textCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'e.g. two margherita pizza, one coke, three naan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _parseOrder,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Parse Order'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Parsed results
            if (_parsed.isNotEmpty) ...[
              Text('Parsed Items (${_parsed.length})', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _parsed.length,
                  itemBuilder: (context, i) {
                    final item = _parsed[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: BrandColors.gold.withValues(alpha: 0.12),
                          child: Text('${item.quantity}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: BrandColors.gold)),
                        ),
                        title: Text(item.product.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                        subtitle: Text('\$${item.product.price.toStringAsFixed(2)} each • Total: \$${(item.product.price * item.quantity).toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                      ),
                    );
                  },
                ),
              ),
              if (!_added)
                ElevatedButton.icon(
                  onPressed: _addToCart,
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: const Text('Add All to Cart'),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('Added to cart!', style: GoogleFonts.plusJakartaSans(color: BrandColors.success, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ParsedItem {
  final Product product;
  final int quantity;
  const _ParsedItem({required this.product, required this.quantity});
}