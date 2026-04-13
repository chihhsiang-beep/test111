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

  static String _getOllamaModelName(AiProvider provider) {
    switch (provider) {
      case AiProvider.gemma2Local:
        return 'gemma2:2b';
      case AiProvider.gemma4Local:
        return 'gemma4:E2B';
      case AiProvider.qwenLocal:
        return 'qwen2.5:latest';
      case AiProvider.geminiApi:
        throw Exception('geminiApi does not use Ollama model name');
    }
  }

  static Future<AiProvider> getCurrentProvider() async {
    return await AISettingsService.getSelectedProvider();
  }
  static const AiProvider _chatProvider = AiProvider.gemma4Local;
  static const AiProvider _translationProvider = AiProvider.gemma2Local;
  static const AiProvider _paraphraseProvider = AiProvider.qwenLocal;

  static Future<void> setCurrentProvider(AiProvider provider) async {
    await AISettingsService.setSelectedProvider(provider);
  }

  static bool _isGemma4Local(AiProvider provider) {
    return provider == AiProvider.gemma4Local;
  }

  // =========================
  // Modular config for NON-gemma4 models
  // gemma4 uses legacy branch below
  // =========================

  static double _getTemperature(
      AiProvider provider,
      String task,
      ) {
    switch (provider) {
      case AiProvider.gemma2Local:
        switch (task) {
          case 'chinese_reply':
            return 0.20;
          case 'translate_en':
          case 'translate_zh':
            return 0.10;
          case 'expression_tips':
            return 0.30;
          default:
            return 0.20;
        }

      case AiProvider.qwenLocal:
        switch (task) {
          case 'chinese_reply':
            return 0.15;
          case 'translate_en':
          case 'translate_zh':
            return 0.10;
          case 'expression_tips':
            return 0.25;
          default:
            return 0.15;
        }

      case AiProvider.geminiApi:
        switch (task) {
          case 'chinese_reply':
            return 0.20;
          case 'translate_en':
          case 'translate_zh':
            return 0.10;
          case 'expression_tips':
            return 0.20;
          default:
            return 0.20;
        }

      case AiProvider.gemma4Local:
      // gemma4 不走這套
        return 0.15;
    }
  }

  static int _getMaxTokens(
      AiProvider provider,
      String task,
      ) {
    switch (provider) {
      case AiProvider.gemma2Local:
        switch (task) {
          case 'chinese_reply':
            return 100;
          case 'translate_en':
          case 'translate_zh':
            return 120;
          case 'expression_tips':
            return 220;
          default:
            return 150;
        }

      case AiProvider.qwenLocal:
        switch (task) {
          case 'chinese_reply':
            return 800;
          case 'translate_en':
          case 'translate_zh':
            return 600;
          case 'expression_tips':
            return 400;
          default:
            return 400;
        }

      case AiProvider.geminiApi:
        switch (task) {
          case 'chinese_reply':
            return 120;
          case 'translate_en':
          case 'translate_zh':
            return 120;
          case 'expression_tips':
            return 180;
          default:
            return 150;
        }

      case AiProvider.gemma4Local:
      // gemma4 不走這套
        return 400;
    }
  }

  // =========================
  // Core generation
  // =========================

  static Future<String> _generateText(
      String prompt, {
        double temperature = 0.3,
        int maxOutputTokens = 800,
      }) async {
    final provider = await getCurrentProvider();
    return _generateTextWithProvider(
      provider,
      prompt,
      temperature: temperature,
      maxOutputTokens: maxOutputTokens,
    );
  }

  static Future<String> _generateTextWithProvider(
      AiProvider provider,
      String prompt, {
        double temperature = 0.3,
        int maxOutputTokens = 800,
      }) async {
    switch (provider) {
      case AiProvider.gemma2Local:
      case AiProvider.gemma4Local:
      case AiProvider.qwenLocal:
        return await _callOllama(
          prompt,
          provider: provider,
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
          return await _callOllama(
            prompt,
            provider: AiProvider.gemma2Local,
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
        required AiProvider provider,
        double temperature = 0.3,
        int maxTokens = 1500,
      }) async {
    try {
      final modelName = _getOllamaModelName(provider);

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

  // =========================
  // gemma4 legacy branch
  // =========================

  static Future<String> _gemma4LegacyTranslateToEnglish(String text) async {
    const provider = AiProvider.gemma4Local;

    final prompt = AiPromptService.buildTranslateToEnglishPrompt(
      provider,
      text,
    );

    final raw = await _generateTextWithProvider(
      provider,
      prompt,
      temperature: 0.2,
      maxOutputTokens: 800,
    );

    return _cleanPlainText(raw);
  }

  static Future<String> _gemma4LegacyTranslateToTraditionalChinese(
      String text,
      ) async {
    const provider = AiProvider.gemma4Local;

    final prompt = AiPromptService.buildTranslateToTraditionalChinesePrompt(
      provider,
      text,
    );

    final raw = await _generateTextWithProvider(
      provider,
      prompt,
      temperature: 0.2,
      maxOutputTokens: 800,
    );

    return _cleanPlainText(raw);
  }

  static Future<String> _gemma4LegacyChineseReply(
      String conversationContext,
      String userText,
      ) async {
    const provider = AiProvider.gemma4Local;

    final prompt = AiPromptService.buildChineseReplyPrompt(
      provider,
      '',
      userText,
    );

    debugPrint('==== CHINESE REPLY PROMPT ====');
    debugPrint(prompt);

    final raw = await _generateTextWithProvider(
      provider,
      prompt,
      temperature: 0.15,
      maxOutputTokens: 800,
    );

    debugPrint('==== RAW CHINESE REPLY ====');
    debugPrint(raw);

    final cleaned = _cleanPlainText(raw);

    debugPrint('==== CLEANED CHINESE REPLY ====');
    debugPrint(cleaned);

    if (cleaned.isEmpty) {
      return '我在喔';
    }

    if (_looksMostlyEnglish(cleaned)) {
      final translated = await _gemma4LegacyTranslateToTraditionalChinese(
        cleaned,
      );
      final result = _cleanShortChineseReply(translated);
      return result.isEmpty ? '我在喔' : result;
    }

    final result = _cleanShortChineseReply(cleaned);
    return result.isEmpty ? '我在喔' : result;
  }

  static Future<String> _gemma4LegacyExpressionTips(String sentence) async {
    const provider = AiProvider.gemma4Local;

    String englishSentence = sentence.trim();
    if (!_looksMostlyEnglish(englishSentence)) {
      englishSentence = await _gemma4LegacyTranslateToEnglish(englishSentence);
    }

    final prompt = AiPromptService.buildExpressionTipsPrompt(
      provider,
      englishSentence,
    );

    final raw = await _generateTextWithProvider(
      provider,
      prompt,
      temperature: 0.3,
      maxOutputTokens: 800,
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

  // =========================
  // Public tasks
  // =========================

  static Future<String> translateToEnglish(String text) async {
    const provider = _translationProvider;

    final prompt = AiPromptService.buildTranslateToEnglishPrompt(
      provider,
      text,
    );

    final raw = await _generateTextWithProvider(
      provider,
      prompt,
      temperature: 0.10,
      maxOutputTokens: 800,
    );

    return _cleanPlainText(raw);
  }

  static Future<String> translateToTraditionalChinese(String text) async {
    const provider = _translationProvider;

    final prompt = AiPromptService.buildTranslateToTraditionalChinesePrompt(
      provider,
      text,
    );

    final raw = await _generateTextWithProvider(
      provider,
      prompt,
      temperature: 0.10,
      maxOutputTokens: 800,
    );

    return _cleanPlainText(raw);
  }

  static bool _isKnowledgeStyleQuestion(String text) {
    final t = text.trim();

    // 明確的知識 / 解釋型問句
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

    // 常見寒暄 / 日常聊天，直接排除
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

    // 只有較長、較像提問內容時才當知識問題
    if (t.length >= 12) return true;

    return false;
  }

  static String _buildKnowledgeReplyPrompt(String userText) {
    return '''
你是 Amy。
請用繁體中文自然回答使用者的問題。

規則：
1. 用繁體中文
2. 可以簡短解釋
3. 回答自然，不要太制式
4. 以 1 到 3 句為主
5. 不要列點
6. 不要留白
7. 不要重複使用者原句
8. 直接回答，不要先說「這要看角度」或「很複雜」

使用者：
$userText

回覆：
''';
  }

  static Future<String> getChineseReply(
      String conversationContext,
      String userText,
      ) async {
    final provider = await getCurrentProvider();

    final isKnowledgeQuestion = _isKnowledgeStyleQuestion(userText);

    final prompt = isKnowledgeQuestion
        ? _buildKnowledgeReplyPrompt(userText)
        : AiPromptService.buildChineseReplyPrompt(
      provider,
      provider == AiProvider.gemma4Local ? '' : conversationContext,
      userText,
    );

    debugPrint('==== CHINESE REPLY PROMPT ====');
    debugPrint(prompt);

    final raw = await _generateText(
      prompt,
      temperature: isKnowledgeQuestion ? 0.2 : 0.15,
      maxOutputTokens: isKnowledgeQuestion ? 220 : 400,
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
    const provider = AiProvider.qwenLocal;
    final originalSentence = sentence.trim();

    final prompt = '''
You are an English learning assistant.

Task:
For the sentence below, do all of the following:
1. Translate it into natural English
2. Give 2 different natural English paraphrases
3. Give 1 short grammar or usage tip

STRICT RULES:
1. Output in English only
2. Do NOT use markdown
3. Do NOT use bullet points
4. Do NOT add any extra explanation
5. Output EXACTLY in this format:

Original: ...
Alternative 1: ...
Alternative 2: ...
Note: ...

6. If the input is Chinese, first translate it naturally
7. Alternative 1 and Alternative 2 must be clearly different from Original
8. Keep everything short and natural

Sentence:
$originalSentence
''';

    final raw = await _callOllama(
      prompt,
      provider: provider,
      temperature: 0.2,
      maxTokens: 260,
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

    return 'Original: $finalOriginal\n'
        'Alternative 1: $finalAlt1\n'
        'Alternative 2: $finalAlt2\n'
        'Note: $finalNote';
  }

  // =========================
  // Helpers
  // =========================

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