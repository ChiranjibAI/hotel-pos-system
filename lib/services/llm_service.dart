import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Configuration for the LLM endpoint (Ollama or OpenAI-compatible).
class LlmConfig {
  /// Endpoint URL. Default: Ollama local chat endpoint.
  /// For OpenAI: https://api.openai.com/v1/chat/completions
  final String endpoint;

  /// API key (optional for Ollama, required for OpenAI).
  final String apiKey;

  /// Model name (e.g. "llama3.2" for Ollama, "gpt-4o-mini" for OpenAI).
  final String model;

  const LlmConfig({
    this.endpoint = 'http://localhost:11434/api/chat',
    this.apiKey = '',
    this.model = 'llama3.2',
  });

  bool get isOpenAI => endpoint.contains('openai.com') || endpoint.contains('/v1/chat/completions');

  Map<String, dynamic> toMap() => {'endpoint': endpoint, 'apiKey': apiKey, 'model': model};
  factory LlmConfig.fromMap(Map<String, dynamic> m) => LlmConfig(
    endpoint: m['endpoint'] as String? ?? 'http://localhost:11434/api/chat',
    apiKey: (m['apiKey'] as String?) ?? '',
    model: m['model'] as String? ?? 'llama3.2',
  );
}

/// LLM Service — talks to an Ollama or OpenAI-compatible chat endpoint.
///
/// Configuration is stored in SharedPreferences so the owner can set
/// the endpoint/model/key once. All LLM-backed features go through
/// this service and must gracefully degrade when the endpoint is
/// unreachable (each feature provides its own non-LLM fallback).
class LlmService extends ChangeNotifier {
  LlmService._();
  static final LlmService instance = LlmService._();

  static const _prefKey = 'llm_config_v1';

  LlmConfig _config = const LlmConfig();
  bool _initialized = false;

  LlmConfig get config => _config;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null) {
        _config = LlmConfig.fromMap(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (e) {
      if (kDebugMode) print('[LlmService] init failed: $e');
    }
  }

  Future<void> saveConfig(LlmConfig cfg) async {
    _config = cfg;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, jsonEncode(cfg.toMap()));
    } catch (e) {
      if (kDebugMode) print('[LlmService] save failed: $e');
    }
    notifyListeners();
  }

  /// Send a chat prompt to the LLM. Returns the text response, or
  /// null if the endpoint is unreachable or errors.
  Future<String?> chat(String prompt, {String? system, Duration timeout = const Duration(seconds: 30)}) async {
    await initialize();
    try {
      if (_config.isOpenAI) {
        return await _chatOpenAI(prompt, system: system, timeout: timeout);
      }
      return await _chatOllama(prompt, system: system, timeout: timeout);
    } catch (e) {
      if (kDebugMode) print('[LlmService] chat failed: $e');
      return null;
    }
  }

  Future<String?> _chatOllama(String prompt, {String? system, required Duration timeout}) async {
    final body = <String, dynamic>{
      'model': _config.model,
      'messages': [
        if (system != null) {'role': 'system', 'content': system},
        {'role': 'user', 'content': prompt},
      ],
      'stream': false,
    };
    final resp = await http.post(
      Uri.parse(_config.endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(timeout);
    if (resp.statusCode != 200) return null;
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final msg = data['message'] as Map<String, dynamic>?;
    return msg?['content'] as String?;
  }

  Future<String?> _chatOpenAI(String prompt, {String? system, required Duration timeout}) async {
    final body = <String, dynamic>{
      'model': _config.model,
      'messages': [
        if (system != null) {'role': 'system', 'content': system},
        {'role': 'user', 'content': prompt},
      ],
    };
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_config.apiKey.isNotEmpty) headers['Authorization'] = 'Bearer ${_config.apiKey}';
    final resp = await http.post(
      Uri.parse(_config.endpoint),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(timeout);
    if (resp.statusCode != 200) return null;
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) return null;
    final msg = (choices[0] as Map<String, dynamic>)['message'] as Map<String, dynamic>?;
    return msg?['content'] as String?;
  }

  /// Quick ping to check if the endpoint is reachable.
  Future<bool> isAvailable() async {
    await initialize();
    final result = await chat('Reply with OK', timeout: const Duration(seconds: 10));
    return result != null && result.isNotEmpty;
  }
}