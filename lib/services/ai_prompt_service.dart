import '../models/ai_provider.dart';
import 'prompts/gemma2_local_prompts.dart';
import 'prompts/gemma4_local_prompts.dart';
import 'prompts/gemini_prompts.dart';

class AiPromptService {
  static String buildTranslateToEnglishPrompt(
      AiProvider provider,
      String text,
      ) {
    switch (provider) {
      case AiProvider.gemma2Local:
        return Gemma2LocalPrompts.buildTranslateToEnglishPrompt(text);
      case AiProvider.gemma4Local:
        return Gemma4LocalPrompts.buildTranslateToEnglishPrompt(text);
      case AiProvider.qwenLocal:
        return Gemma4LocalPrompts.buildTranslateToEnglishPrompt(text);
      case AiProvider.geminiApi:
        return GeminiPrompts.buildTranslateToEnglishPrompt(text);
    }
  }

  static String buildTranslateToTraditionalChinesePrompt(
      AiProvider provider,
      String text,
      ) {
    switch (provider) {
      case AiProvider.gemma2Local:
        return Gemma2LocalPrompts.buildTranslateToTraditionalChinesePrompt(text);
      case AiProvider.gemma4Local:
        return Gemma4LocalPrompts.buildTranslateToTraditionalChinesePrompt(text);
      case AiProvider.qwenLocal:
        return Gemma4LocalPrompts.buildTranslateToTraditionalChinesePrompt(text);
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
      case AiProvider.gemma2Local:
        return Gemma2LocalPrompts.buildChineseReplyPrompt(
          conversationContext,
          userText,
        );
      case AiProvider.gemma4Local:
        return Gemma4LocalPrompts.buildChineseReplyPrompt(
          conversationContext,
          userText,
        );
      case AiProvider.qwenLocal:
        return Gemma4LocalPrompts.buildChineseReplyPrompt(
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
      case AiProvider.gemma2Local:
        return Gemma2LocalPrompts.buildExpressionTipsPrompt(englishSentence);
      case AiProvider.gemma4Local:
        return Gemma4LocalPrompts.buildExpressionTipsPrompt(englishSentence);
      case AiProvider.qwenLocal:
        return Gemma4LocalPrompts.buildExpressionTipsPrompt(englishSentence);
      case AiProvider.geminiApi:
        return GeminiPrompts.buildExpressionTipsPrompt(englishSentence);
    }
  }
}