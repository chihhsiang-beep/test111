import 'prompts/gemma2_local_prompts.dart';
import 'prompts/gemma4_local_prompts.dart';
import 'prompts/qwen_local_prompts.dart';

class AiPromptService {
  static String buildChatReplyPrompt(
      String conversationContext,
      String userText,
      ) {
    return Gemma4LocalPrompts.buildChineseReplyPrompt(
      conversationContext,
      userText,
    );
  }

  static String buildKnowledgeReplyPrompt(String userText) {
    return Gemma4LocalPrompts.buildKnowledgeReplyPrompt(userText);
  }

  static String buildTranslateToEnglishPrompt(String text) {
    return Gemma2LocalPrompts.buildTranslateToEnglishPrompt(text);
  }

  static String buildTranslateToTraditionalChinesePrompt(String text) {
    return Gemma2LocalPrompts.buildTranslateToTraditionalChinesePrompt(text);
  }

  static String buildExpressionTipsPrompt(String sentence) {
    return QwenLocalPrompts.buildExpressionTipsPrompt(sentence);
  }
}