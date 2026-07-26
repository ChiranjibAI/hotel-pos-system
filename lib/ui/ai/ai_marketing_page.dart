import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/components/style/pop_button.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/services/ai_marketing_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// AI WhatsApp Marketing page — generate promotional messages and
/// send them to loyalty customers via WhatsApp (wa.me links).
class AiMarketingPage extends StatefulWidget {
  const AiMarketingPage({super.key});

  @override
  State<AiMarketingPage> createState() => _AiMarketingPageState();
}

class _AiMarketingPageState extends State<AiMarketingPage> {
  final _messageCtrl = TextEditingController();
  final _dishCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '10');
  bool _loading = false;
  String _theme = 'daily special';
  List<String> _recipients = [];

  @override
  void dispose() {
    _messageCtrl.dispose();
    _dishCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() => _loading = true);
    final msg = await AiMarketingService.instance.generateMessage(
      dishName: _dishCtrl.text.trim(),
      discountPercent: _discountCtrl.text.trim().isEmpty ? '10' : _discountCtrl.text.trim(),
      theme: _theme,
    );
    if (mounted) {
      setState(() {
        _messageCtrl.text = msg;
        _loading = false;
        _recipients = AiMarketingService.instance.inactiveCustomers();
      });
    }
  }

  Future<void> _sendWhatsApp(String phone) async {
    final msg = _messageCtrl.text.trim();
    if (msg.isEmpty || phone.isEmpty) return;
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final url = 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(msg)}';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Marketing'),
        leading: const PopButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildThemeSelector(),
          const SizedBox(height: 16),
          _buildInputField('Featured dish (optional)', _dishCtrl, Icons.restaurant_menu_outlined),
          const SizedBox(height: 12),
          _buildInputField('Discount %', _discountCtrl, Icons.percent_outlined),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loading ? null : _generate,
            icon: _loading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome),
            label: Text('Generate Message', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 20),
          Text('MESSAGE PREVIEW', style: GoogleFonts.plusJakartaSans(
            fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: BrandColors.gold,
          )),
          const SizedBox(height: 8),
          TextField(
            controller: _messageCtrl,
            maxLines: 6,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: 'Generate a message or write your own...',
            ),
          ),
          const SizedBox(height: 20),
          if (_recipients.isNotEmpty) ...[
            Text('RECIPIENTS (${_recipients.length})', style: GoogleFonts.plusJakartaSans(
              fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: BrandColors.gold,
            )),
            const SizedBox(height: 8),
            ..._recipients.take(20).map((phone) => Card(
              child: ListTile(
                leading: Icon(Icons.person_outline, color: BrandColors.gold),
                title: Text(phone, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                trailing: IconButton(
                  icon: const Icon(Icons.send_rounded, color: BrandColors.success),
                  onPressed: () => _sendWhatsApp(phone),
                ),
                onTap: () => _sendWhatsApp(phone),
              ),
            )),
            if (_recipients.length > 20)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('+ ${_recipients.length - 20} more',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildThemeSelector() {
    const themes = ['daily special', 'loyalty win-back', 'slow-moving dish', 'weekend offer'];
    return Wrap(
      spacing: 8,
      children: themes.map((t) {
        final selected = t == _theme;
        return ChoiceChip(
          label: Text(t, style: GoogleFonts.plusJakartaSans(fontSize: 12)),
          selected: selected,
          selectedColor: BrandColors.gold.withValues(alpha: 0.15),
          onSelected: (_) => setState(() => _theme = t),
        );
      }).toList(),
    );
  }

  Widget _buildInputField(String label, TextEditingController ctrl, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: BrandColors.gold)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}