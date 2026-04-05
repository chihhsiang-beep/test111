import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _ollamaUrl = 'http://10.0.2.2:11434/api/generate';
  static const String _modelName = 'gemma2:2b';

  // 統一呼叫 Ollama 的私有方法
  static Future<String> _callOllama(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_ollamaUrl),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': _modelName,
          'prompt': prompt,
          'stream': false,
          'options': {'temperature': 0.7},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['response'] ?? '').toString().trim();
      }
      return '錯誤：連線失敗 (${response.statusCode})';
    } catch (e) {
      return '錯誤：請檢查 Ollama 是否已開啟';
    }
  }

  // 翻譯功能
  static Future<String> translate(String text) async {
    final prompt = "你是一個專業中翻英助手。請把這句中文翻譯成地道英文，只輸出英文內容：$text";
    return await _callOllama(prompt);
  }

  // Amy 的中文回覆功能
  static Future<String> getChineseReply(String conversationContext, String userText) async {
    final prompt = '''
你是一個叫 Amy 的英文學習夥伴。
規則：1. 自然回覆使用者。2. 只用繁體中文。3. 回覆 1-3 句。
上下文：$conversationContext
最新訊息：$userText
請直接輸出 Amy 的中文回覆：''';
    return await _callOllama(prompt);
  }
}