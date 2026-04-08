import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/ai_provider.dart';
import 'ai_settings_service.dart';

class AIService {
  static const String _ollamaUrl = 'http://10.0.2.2:11434/api/generate';
  static const String _ollamaModelName = 'gemma2:2b';

  // 路線 A：先寫死，之後再改成 dart-define 或後端代理
  static const String _geminiApiKey = 'AIzaSyAhTbe4oGGu81_M1Ncf_Ei7bgd1w6cmFIQ';

  // 可以先用這個
  static const String _geminiModelName = 'Gemma 4 26B';

  static Future<AiProvider> getCurrentProvider() async {
    return await AISettingsService.getSelectedProvider();
  }

  static Future<void> setCurrentProvider(AiProvider provider) async {
    await AISettingsService.setSelectedProvider(provider);
  }

  static Future<String> _generateText(String prompt) async {
    final provider = await getCurrentProvider();

    switch (provider) {
      case AiProvider.gemmaLocal:
        return await _callOllama(prompt);

      case AiProvider.geminiApi:
        final geminiResult = await _callGemini(prompt);

        if (_isGeminiTemporaryError(geminiResult)) {
          debugPrint('Gemini 暫時失敗，改用 Ollama fallback');
          return await _callOllama(prompt);
        }

        return geminiResult;
    }
  }

  static bool _isGeminiTemporaryError(String text) {
    return text.contains('Gemini 連線失敗 (503)') ||
        text.contains('Gemini 請求失敗') ||
        text.contains('Gemini 沒有回傳內容');
  }

  static Future<String> _callOllama(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_ollamaUrl),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': _ollamaModelName,
          'prompt': prompt,
          'stream': false,
          'options': {
            'temperature': 0.3,
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

  static Future<String> _callGemini(String prompt) async {
    if (_geminiApiKey.isEmpty || _geminiApiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      return '錯誤：請先在 ai_service.dart 填入 Gemini API Key';
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
          '$_geminiModelName:generateContent?key=$_geminiApiKey',
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
            'temperature': 0.3,
          }
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('Gemini error body: ${response.body}');

        if (response.statusCode == 503) {
          return '錯誤：Gemini 伺服器忙碌中 (503)';
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
              .join('\n')
              .trim();

          if (text.isNotEmpty) {
            return text;
          }
        }
      }

      return '錯誤：Gemini 沒有回傳內容';
    } catch (e) {
      debugPrint('_callGemini error: $e');
      return '錯誤：Gemini 請求失敗';
    }
  }

  static Future<String> translateToEnglish(String text) async {
    final prompt = '''
You are a professional translator.
Translate the following text into natural English.

Rules:
1. Output English only.
2. Do not explain.
3. Do not add quotation marks.
4. Keep the meaning natural and conversational.

Text:
$text
''';

    return await _generateText(prompt);
  }

  static Future<String> translateToTraditionalChinese(String text) async {
    final prompt = '''
你是一個專業翻譯助手。
請把以下內容翻譯成自然、口語、繁體中文。

規則：
1. 只輸出繁體中文。
2. 不要解釋。
3. 不要加引號。
4. 保持語氣自然。

內容：
$text
''';

    return await _generateText(prompt);
  }

  static Future<String> getChineseReply(
      String conversationContext,
      String userText,
      ) async {
    final prompt = '''
你是一個叫 Amy 的英文學習夥伴。

你必須遵守以下規則：
1. 一律只使用繁體中文回覆。
2. 禁止使用英文作為主要回覆內容。
3. 回覆自然、簡短、像聊天。
4. 回覆 1 到 3 句即可。
5. 不要做翻譯說明，不要加註解。
6. 直接輸出 Amy 的回覆內容。

上下文：
$conversationContext

最新訊息：
$userText
''';

    final result = await _generateText(prompt);

    if (_looksMostlyEnglish(result)) {
      return await translateToTraditionalChinese(result);
    }

    return result;
  }

  static Future<String> getExpressionTips(String englishSentence) async {
    final prompt = '''
You are an English learning coach.

Given this sentence:
$englishSentence

Please provide only:

Example:
(one natural example sentence related to this expression)

Usage:
(one short grammar or usage note)

Rules:
1. Use simple English.
2. Keep it short.
3. Do not use markdown.
4. Do not use symbols like **, ##, -, or numbering.
5. Output exactly in this format:

Example:
...

Usage:
...
''';

    return await _generateText(prompt);
  }

  static bool _looksMostlyEnglish(String text) {
    final englishCount = RegExp(r'[A-Za-z]').allMatches(text).length;
    final chineseCount = RegExp(r'[\u4E00-\u9FFF]').allMatches(text).length;
    return englishCount > chineseCount;
  }
}