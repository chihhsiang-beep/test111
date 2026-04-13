import 'prompt_utils.dart';

class QwenLocalPrompts {
  static String buildExpressionTipsPrompt(String sentence) {
    final input = PromptUtils.safeText(sentence);

    return '''
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
$input
''';
  }
}