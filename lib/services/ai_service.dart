import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/ai_provider.dart';
import 'ai_prompt_service.dart';
import 'ai_settings_service.dart';

class AIService {
  static const String _ollamaUrl = 'http://10.0.2.2:11434/api/generate';
  static const String _geminiApiKey = '';
  static const String _geminiModelName = 'gemma-4-31b-it';

  static const String _chatModel = 'gemma4:E2B';
  static const String _translationModel = 'gemma2:2b';
  static const String _paraphraseModel = 'qwen2.5:latest';

  static Future<AiProvider> getCurrentProvider() async {
    return await AISettingsService.getSelectedProvider();
  }

  static Future<void> setCurrentProvider(AiProvider provider) async {
    await AISettingsService.setSelectedProvider(provider);
  }

  static Future<String> _callOllamaByModelName(
      String modelName,
      String prompt, {
        double temperature = 0.3,
        int maxTokens = 800,
      }) async {
    try {
      final response = await http.post(
        Uri.parse(_ollamaUrl),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': modelName,
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
      debugPrint('_callOllamaByModelName error: $e');
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
    final prompt = AiPromptService.buildTranslateToEnglishPrompt(text);

    final raw = await _callOllamaByModelName(
      _translationModel,
      prompt,
      temperature: 0.10,
      maxTokens: 800,
    );

    return _cleanPlainText(raw);
  }

  static Future<String> translateToTraditionalChinese(String text) async {
    final prompt = AiPromptService.buildTranslateToTraditionalChinesePrompt(text);

    final raw = await _callOllamaByModelName(
      _translationModel,
      prompt,
      temperature: 0.10,
      maxTokens: 800,
    );

    return _cleanPlainText(raw);
  }

  static bool _isKnowledgeStyleQuestion(String text) {
    final t = text.trim();

    const strongKeywords = [
      '是什麼',
      '什麼是',
      '為什麼',
      '如何',
      '原理',
      '意思',
      '用途',
      '差別',
      '比較',
      '介紹',
    ];

    for (final k in strongKeywords) {
      if (t.contains(k)) return true;
    }

    const casualPatterns = [
      '你好',
      '你好嗎',
      '您好',
      '早安',
      '午安',
      '晚安',
      '在嗎',
      '你在幹嘛',
      '今天天氣',
      '天氣怎麼樣',
      '天氣如何',
      '吃飯了嗎',
    ];

    for (final k in casualPatterns) {
      if (t.contains(k)) return false;
    }

    if (t.length >= 12) return true;

    return false;
  }

  static Future<String> getChineseReply(
      String conversationContext,
      String userText,
      ) async {
    final isKnowledgeQuestion = _isKnowledgeStyleQuestion(userText);

    final prompt = isKnowledgeQuestion
        ? AiPromptService.buildKnowledgeReplyPrompt(userText)
        : AiPromptService.buildChatReplyPrompt('', userText);

    debugPrint('==== CHINESE REPLY PROMPT ====');
    debugPrint(prompt);

    final raw = await _callOllamaByModelName(
      _chatModel,
      prompt,
      temperature: isKnowledgeQuestion ? 0.2 : 0.15,
      maxTokens: isKnowledgeQuestion ? 220 : 800,
    );

    debugPrint('==== RAW CHINESE REPLY ====');
    debugPrint(raw);

    final cleaned = _cleanPlainText(raw);

    debugPrint('==== CLEANED CHINESE REPLY ====');
    debugPrint(cleaned);

    if (cleaned.isEmpty) {
      return isKnowledgeQuestion ? '這個要看角度。' : '我在喔';
    }

    if (_looksMostlyEnglish(cleaned)) {
      final translated = await translateToTraditionalChinese(cleaned);
      final result = isKnowledgeQuestion
          ? _cleanPlainText(translated)
          : _cleanShortChineseReply(translated);

      if (result.isEmpty) {
        return isKnowledgeQuestion ? '這個要看角度。' : '我在喔';
      }
      return result;
    }

    if (isKnowledgeQuestion) {
      return _cleanPlainText(cleaned);
    }

    final result = _cleanShortChineseReply(cleaned);
    return result.isEmpty ? '我在喔' : result;
  }

  static Future<String> getExpressionTips(String sentence) async {
    final originalSentence = sentence.trim();
    final prompt = AiPromptService.buildExpressionTipsPrompt(originalSentence);

    final raw = await _callOllamaByModelName(
      _paraphraseModel,
      prompt,
      temperature: 0.2,
      maxTokens: 400,
    );

    debugPrint('RAW EXPRESSION TIPS: $raw');

    final cleaned = _cleanPlainText(raw);

    if (cleaned.isEmpty) {
      return 'Alternative 1: ${_buildFallbackAlternative1(originalSentence)}\n'
          'Alternative 2: ${_buildFallbackAlternative2(originalSentence)}\n'
          'Note: Use this in a natural everyday conversation.';
    }

    final originalMatch = RegExp(
      r'(?:Original:)\s*(.+)',
      caseSensitive: false,
    ).firstMatch(cleaned);

    final alt1Match = RegExp(
      r'(?:Alternative 1:)\s*(.+)',
      caseSensitive: false,
    ).firstMatch(cleaned);

    final alt2Match = RegExp(
      r'(?:Alternative 2:)\s*(.+)',
      caseSensitive: false,
    ).firstMatch(cleaned);

    final noteMatch = RegExp(
      r'(?:Note:)\s*(.+)',
      caseSensitive: false,
    ).firstMatch(cleaned);

    final originalEn = originalMatch?.group(1)?.trim() ?? '';
    final alt1 = alt1Match?.group(1)?.trim() ?? '';
    final alt2 = alt2Match?.group(1)?.trim() ?? '';
    final note = noteMatch?.group(1)?.trim() ?? '';

    final finalOriginal = originalEn.isNotEmpty
        ? _cleanPlainText(originalEn)
        : await translateToEnglish(originalSentence);

    final finalAlt1 = alt1.isNotEmpty
        ? _cleanPlainText(alt1)
        : finalOriginal;

    final finalAlt2 = alt2.isNotEmpty
        ? _cleanPlainText(alt2)
        : _buildFallbackAlternative2(finalOriginal);

    final finalNote = note.isNotEmpty
        ? _cleanPlainText(note)
        : 'Use this in a natural everyday conversation.';

    return 'Alternative 1: $finalAlt1\n'
        'Alternative 2: $finalAlt2\n'
        'Note: $finalNote';
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