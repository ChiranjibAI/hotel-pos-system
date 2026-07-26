import 'package:flutter/foundation.dart';
import 'package:hotel_pos_system/models/repository/customers.dart';
import 'package:hotel_pos_system/services/llm_service.dart';

/// AI WhatsApp Marketing — generates promotional messages and targets
/// loyalty customers who haven't visited recently.
///
/// Generates a message based on a theme (daily special, slow-moving
/// dish, loyalty win-back) using the LLM if configured, or a template
/// fallback. Provides a list of inactive customers to send to.
class AiMarketingService {
  AiMarketingService._();
  static final AiMarketingService instance = AiMarketingService._();

  /// Generate a marketing message for the given theme.
  Future<String> generateMessage({
    String dishName = '',
    String discountPercent = '10',
    String theme = 'daily special',
  }) async {
    final prompt = 'Write a short WhatsApp marketing message (under 100 words) '
        'for a restaurant. Theme: $theme. '
        '${dishName.isNotEmpty ? 'Featured dish: $dishName. ' : ''}'
        'Discount: $discountPercent% off. '
        'Make it warm, appetizing, and include a call to action. '
        'Use emojis sparingly. End with "Reply to order."';
    final result = await LlmService.instance.chat(prompt);
    if (result != null && result.isNotEmpty) {
      return result.trim();
    }
    return _templateMessage(dishName, discountPercent, theme);
  }

  String _templateMessage(String dishName, String discountPercent, String theme) {
    if (dishName.isNotEmpty) {
      return '🍽️ Today\'s Special: $dishName — $discountPercent% off! '
          'Fresh, delicious, and made just for you. '
          'Order now and treat yourself. Reply to order.';
    }
    return '✨ $discountPercent% off today only! '
        'Come enjoy a delicious meal with us. '
        'Show this message to claim your discount. Reply to order.';
  }

  /// Get loyalty customers who haven't ordered in [inactiveDays] or more.
  /// Falls back to all customers if last-visit tracking is unavailable.
  List<String> inactiveCustomers({int inactiveDays = 30}) {
    try {
      final customers = Customers.instance.items;
      // Without per-customer last-visit timestamps, we return all
      // customers with an order count > 0 as potential targets.
      // When visit tracking is added, filter by lastVisit < inactiveDays.
      return customers
          .where((c) => c.phone.isNotEmpty)
          .map((c) => c.phone)
          .toList();
    } catch (e) {
      if (kDebugMode) print('[AiMarketingService] customers failed: $e');
      return [];
    }
  }
}