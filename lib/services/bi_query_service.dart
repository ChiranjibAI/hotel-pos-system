import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hotel_pos_system/models/repository/seller.dart';
import 'package:hotel_pos_system/services/llm_service.dart';

/// Answer from the BI query service — either from the LLM or the
/// local keyword fallback.
class BiAnswer {
  final String text;
  final bool fromLlm;
  final Map<String, num>? chartData;

  const BiAnswer({required this.text, this.fromLlm = false, this.chartData});
}

/// Conversational BI — translates an owner's natural-language question
/// into a data-grounded answer.
///
/// Tries the LLM first (if configured). Falls back to keyword matching
/// for common questions (sales, profit, top dish, voids, order count)
/// so the feature works even without an LLM endpoint.
class BiQueryService {
  BiQueryService._();
  static final BiQueryService instance = BiQueryService._();

  Future<BiAnswer> ask(String question) async {
    final data = await _gatherContext();
    // Try LLM first
    final llm = LlmService.instance;
    await llm.initialize();
    final answer = await llm.chat(
      _buildPrompt(question, data),
      system: _systemPrompt,
    );
    if (answer != null && answer.isNotEmpty) {
      return BiAnswer(text: answer.trim(), fromLlm: true);
    }
    // Fallback to keyword matching
    return _keywordFallback(question, data);
  }

  String get _systemPrompt =>
      'You are a restaurant analytics assistant for a small restaurant POS. '
      'Answer the owner\'s question using ONLY the provided data. Be concise, '
      'friendly, and specific. Use Indian Rupees (₹). If the data is insufficient, '
      'say so plainly.';

  String _buildPrompt(String question, Map<String, dynamic> data) {
    return 'Owner\'s question: "$question"\n\n'
        'Today\'s data:\n${_formatData(data)}\n\n'
        'Answer the question in 2-4 sentences.';
  }

  Future<Map<String, dynamic>> _gatherContext() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(const Duration(days: 7));
    final monthStart = now.subtract(const Duration(days: 30));

    try {
      final todayMetrics = await Seller.instance.getMetrics(todayStart, now);
      final weekMetrics = await Seller.instance.getMetrics(weekStart, now);
      final monthMetrics = await Seller.instance.getMetrics(monthStart, now);
      final topItems = await Seller.instance.getMetricsByItems(
        monthStart, now,
        type: OrderMetricType.count,
        target: OrderMetricTarget.product,
      );

      return {
        'today': {
          'orders': todayMetrics.count,
          'revenue': todayMetrics.revenue,
          'cost': todayMetrics.cost,
          'profit': todayMetrics.profit,
        },
        'week': {
          'orders': weekMetrics.count,
          'revenue': weekMetrics.revenue,
          'profit': weekMetrics.profit,
        },
        'month': {
          'orders': monthMetrics.count,
          'revenue': monthMetrics.revenue,
          'profit': monthMetrics.profit,
        },
        'topItems': topItems.take(5).map((e) => {'name': e.name, 'count': e.value}).toList(),
      };
    } catch (e) {
      if (kDebugMode) print('[BiQueryService] gather failed: $e');
      return {};
    }
  }

  String _formatData(Map<String, dynamic> data) {
    if (data.isEmpty) return 'No data available.';
    final buf = StringBuffer();
    final today = data['today'] as Map<String, dynamic>?;
    if (today != null) {
      buf.writeln('Today: ${today['orders']} orders, '
          '₹${today['revenue']} revenue, ₹${today['profit']} profit.');
    }
    final week = data['week'] as Map<String, dynamic>?;
    if (week != null) {
      buf.writeln('This week: ${week['orders']} orders, '
          '₹${week['revenue']} revenue, ₹${week['profit']} profit.');
    }
    final top = data['topItems'] as List?;
    if (top != null && top.isNotEmpty) {
      buf.writeln('Top items (30 days): ${top.map((e) => "${e['name']} (${e['count']})").join(', ')}');
    }
    return buf.toString();
  }

  BiAnswer _keywordFallback(String question, Map<String, dynamic> data) {
    final q = question.toLowerCase();
    final today = data['today'] as Map<String, dynamic>?;
    final week = data['week'] as Map<String, dynamic>?;
    final top = data['topItems'] as List?;

    if (q.contains('today') && (q.contains('sale') || q.contains('revenue') || q.contains('earning'))) {
      if (today == null) return const BiAnswer(text: 'No sales data available for today yet.');
      return BiAnswer(text: 'Today: ${today['orders']} orders, '
          '₹${(today['revenue'] as num).toStringAsFixed(2)} revenue, '
          '₹${(today['profit'] as num).toStringAsFixed(2)} profit.');
    }
    if (q.contains('week') || q.contains('7 day')) {
      if (week == null) return const BiAnswer(text: 'No weekly data available yet.');
      return BiAnswer(text: 'This week: ${week['orders']} orders, '
          '₹${(week['revenue'] as num).toStringAsFixed(2)} revenue, '
          '₹${(week['profit'] as num).toStringAsFixed(2)} profit.');
    }
    if (q.contains('top') || q.contains('best') || q.contains('popular')) {
      if (top == null || top.isEmpty) return const BiAnswer(text: 'No top items data yet — start selling!');
      final items = top.map((e) => "${e['name']} (${e['count']} orders)").join(', ');
      return BiAnswer(text: 'Top selling items (last 30 days): $items');
    }
    if (q.contains('profit')) {
      if (today == null) return const BiAnswer(text: 'No profit data for today yet.');
      return BiAnswer(text: 'Today\'s profit: ₹${(today['profit'] as num).toStringAsFixed(2)} '
          'on ₹${(today['revenue'] as num).toStringAsFixed(2)} revenue.');
    }
    if (q.contains('order') || q.contains('bill')) {
      if (today == null) return const BiAnswer(text: 'No orders recorded today yet.');
      return BiAnswer(text: 'Today: ${today['orders']} orders so far.');
    }
    return BiAnswer(text: 'I can answer questions about today\'s sales, weekly revenue, '
        'top selling items, profit, and order count. Try: "What are today\'s sales?" '
        'or "Top selling dish?"\n\nTo unlock full AI answers, configure an LLM endpoint '
        'in Settings > AI Insights > AI Configuration.');
  }
}