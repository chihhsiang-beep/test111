import 'prompt_utils.dart';

class Gemma4LocalPrompts {
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

  static String buildKnowledgeReplyPrompt(String userText) {
    final input = PromptUtils.safeText(userText);

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
$input

回覆：
''';
  }
}