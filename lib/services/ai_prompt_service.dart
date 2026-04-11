import '../models/ai_provider.dart';
import 'prompts/gemma_local_prompts.dart';
import 'prompts/gemini_prompts.dart';

class AiPromptService {
  static String buildTranslateToEnglishPrompt(
      AiProvider provider,
      String text,
      ) {
    switch (provider) {
      case AiProvider.gemmaLocal:
        return GemmaLocalPrompts.buildTranslateToEnglishPrompt(text);
      case AiProvider.geminiApi:
        return GeminiPrompts.buildTranslateToEnglishPrompt(text);
    }
  }

  static String buildTranslateToTraditionalChinesePrompt(
      AiProvider provider,
      String text,
      ) {
    switch (provider) {
      case AiProvider.gemmaLocal:
        return GemmaLocalPrompts.buildTranslateToTraditionalChinesePrompt(text);
      case AiProvider.geminiApi:
        return GeminiPrompts.buildTranslateToTraditionalChinesePrompt(text);
    }
  }

  static String buildChineseReplyPrompt(
      AiProvider provider,
      String conversationContext,
      String userText,
      ) {
    switch (provider) {
      case AiProvider.gemmaLocal:
        return GemmaLocalPrompts.buildChineseReplyPrompt(
          conversationContext,
          userText,
        );
      case AiProvider.geminiApi:
        return GeminiPrompts.buildChineseReplyPrompt(
          conversationContext,
          userText,
        );
    }
  }

  static String buildExpressionTipsPrompt(
      AiProvider provider,
      String englishSentence,
      ) {
    switch (provider) {
      case AiProvider.gemmaLocal:
        return GemmaLocalPrompts.buildExpressionTipsPrompt(englishSentence);
      case AiProvider.geminiApi:
        return GeminiPrompts.buildExpressionTipsPrompt(englishSentence);
    }
  }
}