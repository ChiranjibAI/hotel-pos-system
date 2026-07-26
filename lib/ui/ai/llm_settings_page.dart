import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/components/style/pop_button.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/services/llm_service.dart';

/// LLM Settings page — configure the AI endpoint (Ollama or
/// OpenAI-compatible). Stores config in SharedPreferences via
/// LlmService.
class LlmSettingsPage extends StatefulWidget {
  const LlmSettingsPage({super.key});

  @override
  State<LlmSettingsPage> createState() => _LlmSettingsPageState();
}

class _LlmSettingsPageState extends State<LlmSettingsPage> {
  final _endpointCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  bool _testing = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    await LlmService.instance.initialize();
    final cfg = LlmService.instance.config;
    _endpointCtrl.text = cfg.endpoint;
    _apiKeyCtrl.text = cfg.apiKey;
    _modelCtrl.text = cfg.model;
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    await LlmService.instance.saveConfig(LlmConfig(
      endpoint: _endpointCtrl.text.trim(),
      apiKey: _apiKeyCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI configuration saved', style: GoogleFonts.plusJakartaSans())),
      );
    }
  }

  Future<void> _testConnection() async {
    setState(() { _testing = true; _testResult = null; });
    await _save();
    final ok = await LlmService.instance.isAvailable();
    if (mounted) {
      setState(() {
        _testing = false;
        _testResult = ok ? 'Connection successful!' : 'Could not reach endpoint. Check URL/network.';
      });
    }
  }

  @override
  void dispose() {
    _endpointCtrl.dispose();
    _apiKeyCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Configuration'),
        leading: const PopButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoBanner(),
          const SizedBox(height: 20),
          _buildField(
            label: 'Endpoint URL',
            controller: _endpointCtrl,
            hint: 'http://localhost:11434/api/chat',
            icon: Icons.link_outlined,
          ),
          const SizedBox(height: 16),
          _buildField(
            label: 'Model name',
            controller: _modelCtrl,
            hint: 'llama3.2',
            icon: Icons.memory_outlined,
          ),
          const SizedBox(height: 16),
          _buildField(
            label: 'API Key (optional, for OpenAI)',
            controller: _apiKeyCtrl,
            hint: 'sk-...',
            icon: Icons.key_outlined,
            obscure: true,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _testing ? null : _testConnection,
                  icon: _testing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.wifi_find_outlined),
                  label: Text('Test Connection', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text('Save', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
          if (_testResult != null) ...[
            const SizedBox(height: 16),
            _buildTestResult(),
          ],
          const SizedBox(height: 32),
          _buildPresetSection(),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BrandColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BrandColors.gold.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: BrandColors.gold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Configure an Ollama or OpenAI-compatible endpoint to enable AI-powered insights. '
              'Features work in basic mode without this.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: BrandColors.gold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildTestResult() {
    final ok = _testResult?.contains('successful') == true;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (ok ? BrandColors.success : BrandColors.danger).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: (ok ? BrandColors.success : BrandColors.danger).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle_outline : Icons.error_outline,
              color: ok ? BrandColors.success : BrandColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(_testResult!, style: GoogleFonts.plusJakartaSans(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildPresetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('QUICK PRESETS', style: GoogleFonts.plusJakartaSans(
          fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: BrandColors.gold,
        )),
        const SizedBox(height: 12),
        _presetTile(
          title: 'Ollama (local)',
          subtitle: 'http://localhost:11434/api/chat • llama3.2',
          onTap: () {
            _endpointCtrl.text = 'http://localhost:11434/api/chat';
            _modelCtrl.text = 'llama3.2';
            _apiKeyCtrl.clear();
            setState(() {});
          },
        ),
        _presetTile(
          title: 'OpenAI',
          subtitle: 'https://api.openai.com/v1/chat/completions • gpt-4o-mini',
          onTap: () {
            _endpointCtrl.text = 'https://api.openai.com/v1/chat/completions';
            _modelCtrl.text = 'gpt-4o-mini';
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _presetTile({required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.bolt_outlined, color: BrandColors.gold),
        title: Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11)),
        onTap: onTap,
      ),
    );
  }
}