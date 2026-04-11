import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/ai_provider.dart';
import 'ai_prompt_service.dart';
import 'ai_settings_service.dart';

class AIService {
  static const String _ollamaUrl = 'http://10.0.2.2:11434/api/generate';
  static const String _ollamaModelName = 'gemma2:2b';

  static const String _geminiApiKey = '';
  static const String _geminiModelName = 'gemma-4-31b-it';

  static Future<AiProvider> getCurrentProvider() async {
    return await AISettingsService.getSelectedProvider();
  }

  static Future<void> setCurrentProvider(AiProvider provider) async {
    await AISettingsService.setSelectedProvider(provider);
  }

  static Future<String> _generateText(
      String prompt, {
        double temperature = 0.3,
        int maxOutputTokens = 150,
      }) async {
    final provider = await getCurrentProvider();

    switch (provider) {
      case AiProvider.gemmaLocal:
        return await _callOllama(
          prompt,
          temperature: temperature,
          maxTokens: maxOutputTokens,
        );

      case AiProvider.geminiApi:
        final geminiResult = await _callGemini(
          prompt,
          temperature: temperature,
          maxOutputTokens: maxOutputTokens,
        );

        if (_isGeminiTemporaryError(geminiResult)) {
          debugPrint('Gemini 暫時失敗，改用 Ollama fallback');
          return await _callOllama(
            prompt,
            temperature: temperature,
            maxTokens: maxOutputTokens,
          );
        }

        return geminiResult;
    }
  }

  static bool _isGeminiTemporaryError(String text) {
    return text.contains('Gemini 連線失敗 (503)') ||
        text.contains('Gemini 請求失敗') ||
        text.contains('Gemini 沒有回傳內容');
  }

  static Future<String> _callOllama(
      String prompt, {
        double temperature = 0.3,
        int maxTokens = 150,
      }) async {
    try {
      final response = await http.post(
        Uri.parse(_ollamaUrl),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': _ollamaModelName,
          'prompt': prompt,
          'stream': false,
          'options': {
            'temperature': temperature,
            'num_predict': maxTokens,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['response'] ?? '').toString().trim();
      }

      return '錯誤：Ollama 連線失敗 (${response.statusCode})';
    } catch (e) {
      debugPrint('_callOllama error: $e');
      return '錯誤：請檢查 Ollama 是否已啟動';
    }
  }

  static Future<String> _callGemini(
      String prompt, {
        double temperature = 0.3,
        int maxOutputTokens = 150,
      }) async {
    if (_geminiApiKey.isEmpty || _geminiApiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      return '錯誤：請先在 ai_service.dart 填入 Gemini API Key';
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModelName:generateContent?key=$_geminiApiKey',
    );

    try {
      final response = await http.post(
        url,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': temperature,
            'maxOutputTokens': maxOutputTokens,
            'topP': 0.8,
            'topK': 20,
          }
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('Gemini error body: ${response.body}');
        if (response.statusCode == 404) {
          return '錯誤：找不到模型 (404)，請檢查模型名稱或 API 版本';
        }
        return '錯誤：Gemini 連線失敗 (${response.statusCode})';
      }

      final data = jsonDecode(response.body);
      final candidates = data['candidates'];

      if (candidates is List && candidates.isNotEmpty) {
        final content = candidates.first['content'];
        final parts = content?['parts'];

        if (parts is List && parts.isNotEmpty) {
          final text = parts
              .map((e) => (e['text'] ?? '').toString())
              .join('')
              .trim();

          return text.isEmpty ? '錯誤：Gemini 沒有回傳內容' : text;
        }
      }

      return '錯誤：Gemini 沒有回傳內容';
    } catch (e) {
      debugPrint('_callGemini error: $e');
      return '錯誤：Gemini 請求失敗';
    }
  }

  static Future<String> translateToEnglish(String text) async {
    final provider = await getCurrentProvider();

    final prompt = AiPromptService.buildTranslateToEnglishPrompt(
      provider,
      text,
    );

    final raw = await _generateText(
      prompt,
      temperature: 0.2,
      maxOutputTokens: 80,
    );

    return _cleanPlainText(raw);
  }

  static Future<String> translateToTraditionalChinese(String text) async {
    final provider = await getCurrentProvider();

    final prompt = AiPromptService.buildTranslateToTraditionalChinesePrompt(
      provider,
      text,
    );

    final raw = await _generateText(
      prompt,
      temperature: 0.2,
      maxOutputTokens: 80,
    );

    return _cleanPlainText(raw);
  }

  static Future<String> getChineseReply(
      String conversationContext,
      String userText,
      ) async {
    final provider = await getCurrentProvider();

    final prompt = AiPromptService.buildChineseReplyPrompt(
      provider,
      conversationContext,
      userText,
    );

    final raw = await _generateText(
      prompt,
      temperature: 0.25,
      maxOutputTokens: 40,
    );

    final cleaned = _cleanPlainText(raw);

    if (_looksMostlyEnglish(cleaned)) {
      final translated = await translateToTraditionalChinese(cleaned);
      return _cleanShortChineseReply(translated);
    }

    return _cleanShortChineseReply(cleaned);
  }

  static Future<String> getExpressionTips(String sentence) async {
    final provider = await getCurrentProvider();

    String englishSentence = sentence.trim();
    if (!_looksMostlyEnglish(englishSentence)) {
      englishSentence = await translateToEnglish(englishSentence);
    }

    final prompt = AiPromptService.buildExpressionTipsPrompt(
      provider,
      englishSentence,
    );

    final raw = await _generateText(
      prompt,
      temperature: 0.3,
      maxOutputTokens: 120,
    );

    debugPrint('RAW EXPRESSION TIPS: $raw');

    if (provider.supportsStrictJsonPrompt) {
      final parsed = _tryParseJsonObject(raw);

      String alt1 = '';
      String alt2 = '';
      String note = '';

      if (parsed != null) {
        alt1 = (parsed['alternative_1'] ?? '').toString().trim();
        alt2 = (parsed['alternative_2'] ?? '').toString().trim();
        note = (parsed['note'] ?? '').toString().trim();
      }

      alt1 = _cleanPlainText(alt1);
      alt2 = _cleanPlainText(alt2);
      note = _cleanPlainText(note);

      if (alt1.isEmpty) alt1 = _buildFallbackAlternative1(englishSentence);
      if (alt2.isEmpty) alt2 = _buildFallbackAlternative2(englishSentence);
      if (note.isEmpty) note = 'Use this in a natural everyday conversation.';

      return 'Alternative 1: $alt1\nAlternative 2: $alt2\nNote: $note';
    } else {
      final cleaned = _cleanPlainText(raw);
      return cleaned.isEmpty
          ? 'Alternative 1: ${_buildFallbackAlternative1(englishSentence)}\n'
          'Alternative 2: ${_buildFallbackAlternative2(englishSentence)}\n'
          'Note: Use this in a natural everyday conversation.'
          : cleaned;
    }
  }

  static Map<String, dynamic>? _tryParseJsonObject(String raw) {
    try {
      final cleaned = _extractJsonObject(raw);
      if (cleaned == null) return null;

      final decoded = jsonDecode(cleaned);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (e) {
      debugPrint('_tryParseJsonObject error: $e');
      return null;
    }
  }

  static String? _extractJsonObject(String text) {
    final cleaned = text.trim();

    if (cleaned.startsWith('{') && cleaned.endsWith('}')) {
      return cleaned;
    }

    final codeBlockMatch =
    RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(cleaned);
    if (codeBlockMatch != null) {
      final inside = codeBlockMatch.group(1)?.trim();
      if (inside != null && inside.startsWith('{') && inside.endsWith('}')) {
        return inside;
      }
    }

    final firstBrace = cleaned.indexOf('{');
    final lastBrace = cleaned.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      return cleaned.substring(firstBrace, lastBrace + 1).trim();
    }

    return null;
  }

  static String _cleanPlainText(String text) {
    var result = text.trim();

    result = result.replaceAll(RegExp(r'^```(?:json)?\s*'), '');
    result = result.replaceAll(RegExp(r'\s*```$'), '');
    result = result.replaceAll('"', '');
    result = result.replaceAll("'", '');
    result = result.trim();

    return result;
  }

  static String _cleanShortChineseReply(String text) {
    var result = _cleanPlainText(text);

    result = result.replaceAll(RegExp(r'^Amy[:：]\s*'), '');
    result = result.replaceAll(RegExp(r'[\r\n]+'), ' ');
    result = result.trim();

    if (result.length > 18) {
      result = result.substring(0, 18).trim();
    }

    return result;
  }

  static bool _looksMostlyEnglish(String text) {
    final englishCount = RegExp(r'[A-Za-z]').allMatches(text).length;
    final chineseCount = RegExp(r'[\u4E00-\u9FFF]').allMatches(text).length;
    return englishCount > chineseCount;
  }

  static String _buildFallbackAlternative1(String sentence) {
    final s = sentence.trim();
    if (s.isEmpty) return 'Could you tell me more?';
    return s;
  }

  static String _buildFallbackAlternative2(String sentence) {
    final s = sentence.trim();
    if (s.isEmpty) return 'Can you explain that a bit more?';

    if (s.toLowerCase().startsWith('can you')) {
      return s.replaceFirst(RegExp(r'(?i)^can you'), 'Could you');
    }

    if (s.toLowerCase().startsWith('how')) {
      return 'Could you explain $s';
    }

    return 'A more natural variation of this sentence.';
  }
}