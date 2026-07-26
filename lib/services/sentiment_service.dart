import 'package:flutter/foundation.dart';

/// Sentiment category.
enum SentimentCategory { positive, neutral, negative }

/// Result of sentiment analysis on a single feedback text.
class SentimentResult {
  final double score; // -1.0 to 1.0
  final SentimentCategory category;
  final List<String> aspects; // food, service, price, etc.

  const SentimentResult({
    required this.score,
    required this.category,
    this.aspects = const [],
  });
}

/// Feedback entry with sentiment.
class FeedbackEntry {
  final String text;
  final int rating; // 1-5
  final DateTime createdAt;
  final SentimentResult sentiment;

  const FeedbackEntry({
    required this.text,
    required this.rating,
    required this.createdAt,
    required this.sentiment,
  });
}

/// Sentiment Analysis — lexicon-based, supports English + Hindi
/// transliterated words. Pure Dart, no ML.
///
/// Analyzes feedback text for positive/negative sentiment and
/// extracts aspect keywords (food, service, price, wait, ambiance).
class SentimentService {
  SentimentService._();
  static final SentimentService instance = SentimentService._();

  // In-memory feedback store (persisted to Storage in a future iteration).
  final List<FeedbackEntry> _feedback = [];

  static const _positiveWords = {
    // English
    'good', 'great', 'excellent', 'amazing', 'delicious', 'tasty', 'fresh',
    'friendly', 'fast', 'quick', 'clean', 'nice', 'love', 'best', 'awesome',
    'fantastic', 'wonderful', 'perfect', 'happy', 'satisfied', 'recommend',
    // Hindi transliterated
    'achha', 'accha', 'mast', 'badhiya', 'swadisht', 'bahut', 'shandaar',
    'zabardast', 'kamal', 'firstclass',
  };

  static const _negativeWords = {
    // English
    'bad', 'terrible', 'awful', 'slow', 'rude', 'cold', 'stale', 'bland',
    'expensive', 'overpriced', 'dirty', 'worst', 'hate', 'disappointing',
    'poor', 'disgusting', 'sick', 'late', 'wrong', 'burnt', 'raw',
    // Hindi transliterated
    'bura', 'bekar', 'kharab', 'ganda', 'mehnga', 'der', 'galat',
  };

  static const _aspectKeywords = {
    'food': ['food', 'dish', 'taste', 'meal', 'khana', 'swad'],
    'service': ['service', 'staff', 'waiter', 'seva'],
    'price': ['price', 'cost', 'expensive', 'cheap', 'daam', 'kimat', 'mehnga', 'sasta'],
    'wait': ['wait', 'slow', 'fast', 'quick', 'late', 'der', 'jaldi'],
    'ambiance': ['ambiance', 'atmosphere', 'decor', 'mahaul', 'environment'],
    'cleanliness': ['clean', 'dirty', 'hygiene', 'saaf', 'ganda'],
  };

  List<FeedbackEntry> get feedback => List.unmodifiable(_feedback);

  /// Analyze a text for sentiment.
  SentimentResult analyze(String text) {
    final words = text.toLowerCase().split(RegExp(r'[\s,.;!?]+'));
    int positive = 0;
    int negative = 0;
    final aspects = <String>{};

    for (final w in words) {
      if (w.isEmpty) continue;
      if (_positiveWords.contains(w)) positive++;
      if (_negativeWords.contains(w)) negative++;
      // Check aspects
      for (final entry in _aspectKeywords.entries) {
        for (final keyword in entry.value) {
          if (w.contains(keyword) || keyword.contains(w)) {
            aspects.add(entry.key);
            break;
          }
        }
      }
    }

    final total = positive + negative;
    final score = total == 0 ? 0.0 : (positive - negative) / total;
    final category = score > 0.2
        ? SentimentCategory.positive
        : (score < -0.2 ? SentimentCategory.negative : SentimentCategory.neutral);

    return SentimentResult(score: score, category: category, aspects: aspects.toList());
  }

  /// Add a feedback entry with sentiment analysis.
  void addFeedback(String text, {int rating = 3}) {
    final sentiment = analyze(text);
    _feedback.add(FeedbackEntry(
      text: text,
      rating: rating,
      createdAt: DateTime.now(),
      sentiment: sentiment,
    ));
  }

  /// Overall sentiment summary.
  Map<SentimentCategory, int> get summary {
    final counts = <SentimentCategory, int>{
      SentimentCategory.positive: 0,
      SentimentCategory.neutral: 0,
      SentimentCategory.negative: 0,
    };
    for (final f in _feedback) {
      counts[f.sentiment.category] = (counts[f.sentiment.category] ?? 0) + 1;
    }
    return counts;
  }
}