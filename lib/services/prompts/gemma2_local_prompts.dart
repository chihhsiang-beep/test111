import 'prompt_utils.dart';

class Gemma2LocalPrompts {
  static String buildTranslateToEnglishPrompt(String text) {
    final input = PromptUtils.safeText(text);

    return '''
You are a natural English translator.

Task:
Translate the sentence into natural spoken English.

Rules:
1. Do NOT translate word-by-word.
2. Adapt the meaning naturally.
3. Use casual, native-like phrasing.
4. Keep it short.
5. Output English only.
6. No explanation.
7. No quotation marks.

Sentence:
$input
''';
  }

  static String buildTranslateToTraditionalChinesePrompt(String text) {
    final input = PromptUtils.safeText(text);

    return '''
你是自然繁體中文翻譯助手。

任務：
把句子翻譯成自然、口語、符合中文習慣的繁體中文。

規則：
1. 不要逐字翻譯。
2. 以自然表達為主。
3. 保持簡潔。
4. 只輸出翻譯結果。
5. 不要解釋。
6. 不要加引號。

句子：
$input
''';
  }

  static String buildChineseReplyPrompt(
      String conversationContext,
      String userText,
      ) {
    final context = PromptUtils.shortContext(conversationContext);
    final input = PromptUtils.safeText(userText);

    return '''
你是 Amy。
請用繁體中文簡短回應使用者。

規則：
1. 只回一句
2. 簡短自然
3. 不要解釋

對話：
$context

使用者：
$input

回覆：
''';
  }

  static String buildExpressionTipsPrompt(String englishSentence) {
    final input = PromptUtils.safeText(englishSentence);

    return '''
Rewrite this sentence in 2 natural ways.
Then give 1 short tip.

Format:
Alternative 1: ...
Alternative 2: ...
Note: ...

Sentence:
$input
''';
  }
}