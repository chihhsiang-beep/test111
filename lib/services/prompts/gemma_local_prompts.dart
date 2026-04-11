import 'prompt_utils.dart';

class GemmaLocalPrompts {
  static String buildTranslateToEnglishPrompt(String text) {
    final input = PromptUtils.safeText(text);

    return '''
Translate to natural English.
Output English only.
No explanation.

Text:
$input
''';
  }

  static String buildTranslateToTraditionalChinesePrompt(String text) {
    final input = PromptUtils.safeText(text);

    return '''
請翻譯成自然繁體中文。
只輸出翻譯結果。
不要解釋。

內容：
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