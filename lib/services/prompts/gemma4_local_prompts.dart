import 'prompt_utils.dart';

class Gemma4LocalPrompts {
  static String buildTranslateToEnglishPrompt(String text) {
    final input = PromptUtils.safeText(text);

    return '''
You are a translation assistant.
Translate the following text into natural English.

Rules:
1. Output English only.
2. No explanation.
3. No quotation marks.
4. Keep it concise and natural.

Text:
$input
''';
  }

  static String buildTranslateToTraditionalChinesePrompt(String text) {
    final input = PromptUtils.safeText(text);

    return '''
你是翻譯助手。
請將以下內容翻譯成自然的繁體中文。

規則：
1. 只輸出繁體中文
2. 不要解釋
3. 不要加引號
4. 保持自然簡短

內容：
$input
''';
  }

  static String buildChineseReplyPrompt(
      String conversationContext,
      String userText,
      ) {
    final input = PromptUtils.safeText(userText);

    return '''
你是 Amy。
請直接用繁體中文回覆使用者最後一句話。

規則：
1. 只能一句話
2. 簡短自然
3. 不要解釋
4. 不要留白
5. 不要答非所問
6. 不要重複使用者原句

使用者：
$input

回覆：
''';
  }

  static String buildExpressionTipsPrompt(String englishSentence) {
    final input = PromptUtils.safeText(englishSentence);

    return '''
You are an English learning assistant.

Task:
Give exactly:
- 2 natural alternative expressions
- 1 short usage tip

Rules:
1. English only.
2. No markdown.
3. No headings.
4. No bullet points.
5. Keep it short and natural.
6. Use exactly this format:

Alternative 1: ...
Alternative 2: ...
Note: ...

Sentence:
$input
''';
  }
}