import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/components/style/pop_button.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/models/menu/product.dart';
import 'package:hotel_pos_system/models/repository/menu.dart';
import 'package:hotel_pos_system/services/llm_service.dart';

/// AI Menu Description Generator — generates appetizing descriptions
/// for menu items via the configured LLM, or via template fallback.
class MenuDescriptionGeneratorPage extends StatefulWidget {
  const MenuDescriptionGeneratorPage({super.key});

  @override
  State<MenuDescriptionGeneratorPage> createState() =>
      _MenuDescriptionGeneratorPageState();
}

class _MenuDescriptionGeneratorPageState
    extends State<MenuDescriptionGeneratorPage> {
  String? _generated;
  bool _loading = false;
  Product? _selected;

  @override
  Widget build(BuildContext context) {
    final products = Menu.instance.products.toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Menu Descriptions'),
        leading: const PopButton(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<Product>(
              value: _selected,
              decoration: const InputDecoration(
                labelText: 'Select menu item',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.restaurant_menu_outlined),
              ),
              items: products.map((p) => DropdownMenuItem(
                value: p,
                child: Text(p.name, style: GoogleFonts.plusJakartaSans()),
              )).toList(),
              onChanged: (p) => setState(() { _selected = p; _generated = null; }),
            ),
          ),
          if (_selected != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _generate,
                      icon: _loading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.auto_awesome),
                      label: Text('Generate Description', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: _generated == null
                ? _buildEmpty(products.length)
                : _buildResult(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(int count) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 48, color: BrandColors.gold.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(count == 0 ? 'No menu items yet' : 'Select an item and generate',
                style: GoogleFonts.plusJakartaSans(fontSize: 15, color: Theme.of(context).textTheme.bodySmall?.color),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Generated Description', style: GoogleFonts.plusJakartaSans(
            fontSize: 12, fontWeight: FontWeight.w700, color: BrandColors.gold,
          )),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BrandColors.gold.withValues(alpha: 0.2)),
              ),
              child: SingleChildScrollView(
                child: SelectableText(_generated!, style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.5)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _copyToClipboard(),
            icon: const Icon(Icons.copy_outlined),
            label: Text('Copy to Clipboard', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard() {
    if (_generated == null) return;
    // ignore: deprecated
    Clipboard.setData(ClipboardData(text: _generated!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied!', style: GoogleFonts.plusJakartaSans())),
    );
  }

  Future<void> _generate() async {
    if (_selected == null) return;
    setState(() => _loading = true);
    final product = _selected!;
    final prompt = 'Write an appetizing 1-2 sentence menu description for a dish '
        'called "${product.name}" priced at ₹${product.price}. '
        'Make it sound delicious and inviting, suitable for a QR ordering menu. '
        'Keep it under 30 words.';
    final result = await LlmService.instance.chat(prompt);
    if (mounted) {
      setState(() {
        _generated = (result != null && result.isNotEmpty)
            ? result.trim()
            : _templateFallback(product);
        _loading = false;
      });
    }
  }

  String _templateFallback(Product product) {
    return 'Savor our ${product.name}, prepared fresh with premium ingredients. '
        'A customer favorite at just ₹${product.price.toStringAsFixed(0)}. '
        'Order now and enjoy a delicious meal!';
  }
}