import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/services/bi_query_service.dart';
import 'package:hotel_pos_system/services/llm_service.dart';

/// Owner Chat — conversational BI for restaurant owners.
///
/// Owner types a question about their business, gets a data-grounded
/// answer. Works with keyword fallback (no LLM needed) or full LLM
/// answers when configured.
class OwnerChatPage extends StatefulWidget {
  const OwnerChatPage({super.key});

  @override
  State<OwnerChatPage> createState() => _OwnerChatPageState();
}

class _OwnerChatPageState extends State<OwnerChatPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _loading = false;

  static const _suggestions = [
    "What are today's sales?",
    'Top selling dish?',
    'How much profit this week?',
    'How many orders today?',
  ];

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text.trim(), fromUser: true));
      _loading = true;
    });
    _inputCtrl.clear();
    _scrollToBottom();

    final answer = await BiQueryService.instance.ask(text);
    if (mounted) {
      setState(() {
        _messages.add(_ChatMessage(
          text: answer.text,
          fromUser: false,
          fromLlm: answer.fromLlm,
        ));
        _loading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask Your POS'),
        actions: [
          ListenableBuilder(
            listenable: LlmService.instance,
            builder: (context, _) {
              final configured = LlmService.instance.config.apiKey.isNotEmpty ||
                  LlmService.instance.config.endpoint != 'http://localhost:11434/api/chat';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Chip(
                  label: Text(configured ? 'AI' : 'Basic', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700)),
                  backgroundColor: configured
                      ? BrandColors.gold.withValues(alpha: 0.15)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  side: BorderSide(color: configured ? BrandColors.gold.withValues(alpha: 0.3) : Colors.transparent),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_loading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _messages.length) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessage(_messages[i]);
                    },
                  ),
          ),
          if (_messages.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                spacing: 8,
                children: _suggestions.map((s) => ActionChip(
                  label: Text(s, style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                  onPressed: () => _send(s),
                )).toList(),
              ),
            ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_outlined, size: 56, color: BrandColors.gold.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text('Ask about your sales, profit, top dishes',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Try one of the suggestions below',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(_ChatMessage msg) {
    final isUser = msg.fromUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: BrandColors.gold.withValues(alpha: 0.12),
              child: Icon(Icons.smart_toy_outlined, color: BrandColors.gold, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? BrandColors.gold.withValues(alpha: 0.12)
                    : Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(14),
                border: isUser
                    ? null
                    : Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(msg.text, style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.4)),
                  if (!isUser && msg.fromLlm) ...[
                    const SizedBox(height: 4),
                    Text('AI-generated', style: GoogleFonts.plusJakartaSans(
                      fontSize: 9, color: BrandColors.gold.withValues(alpha: 0.7), fontWeight: FontWeight.w600,
                    )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: BrandColors.gold.withValues(alpha: 0.12),
            child: Icon(Icons.smart_toy_outlined, color: BrandColors.gold, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputCtrl,
                textInputAction: TextInputAction.send,
                onSubmitted: _send,
                decoration: InputDecoration(
                  hintText: 'Ask about your business...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _loading ? null : () => _send(_inputCtrl.text),
              icon: const Icon(Icons.send_rounded),
              style: IconButton.styleFrom(backgroundColor: BrandColors.gold),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool fromUser;
  final bool fromLlm;
  const _ChatMessage({required this.text, required this.fromUser, this.fromLlm = false});
}