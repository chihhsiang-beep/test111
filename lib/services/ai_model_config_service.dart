import '../models/ai_provider.dart';
import '../models/ai_task_type.dart';

class AiGenerationConfig {
  final double temperature;
  final int maxTokens;

  const AiGenerationConfig({
    required this.temperature,
    required this.maxTokens,
  });
}

class AiModelConfigService {
  static AiGenerationConfig getConfig(
      AiProvider provider,
      AiTaskType task,
      ) {
    switch (provider) {
      case AiProvider.gemma2Local:
        switch (task) {
          case AiTaskType.chineseReply:
            return const AiGenerationConfig(
              temperature: 0.2,
              maxTokens: 80,
            );
          case AiTaskType.translateToEnglish:
            return const AiGenerationConfig(
              temperature: 0.1,
              maxTokens: 120,
            );
          case AiTaskType.translateToChinese:
            return const AiGenerationConfig(
              temperature: 0.1,
              maxTokens: 120,
            );
          case AiTaskType.expressionTips:
            return const AiGenerationConfig(
              temperature: 0.3,
              maxTokens: 220,
            );
        }

      case AiProvider.gemma4Local:
        switch (task) {
          case AiTaskType.chineseReply:
            return const AiGenerationConfig(
              temperature: 0.15,
              maxTokens: 400,
            );
          case AiTaskType.translateToEnglish:
            return const AiGenerationConfig(
              temperature: 0.2,
              maxTokens: 800,
            );
          case AiTaskType.translateToChinese:
            return const AiGenerationConfig(
              temperature: 0.2,
              maxTokens: 800,
            );
          case AiTaskType.expressionTips:
            return const AiGenerationConfig(
              temperature: 0.2,
              maxTokens: 800,
            );
        }

      case AiProvider.qwenLocal:
        switch (task) {
          case AiTaskType.chineseReply:
            return const AiGenerationConfig(
              temperature: 0.15,
              maxTokens: 180,
            );
          case AiTaskType.translateToEnglish:
            return const AiGenerationConfig(
              temperature: 0.1,
              maxTokens: 160,
            );
          case AiTaskType.translateToChinese:
            return const AiGenerationConfig(
              temperature: 0.1,
              maxTokens: 160,
            );
          case AiTaskType.expressionTips:
            return const AiGenerationConfig(
              temperature: 0.25,
              maxTokens: 240,
            );
        }

      case AiProvider.geminiApi:
        switch (task) {
          case AiTaskType.chineseReply:
            return const AiGenerationConfig(
              temperature: 0.2,
              maxTokens: 120,
            );
          case AiTaskType.translateToEnglish:
            return const AiGenerationConfig(
              temperature: 0.1,
              maxTokens: 120,
            );
          case AiTaskType.translateToChinese:
            return const AiGenerationConfig(
              temperature: 0.1,
              maxTokens: 120,
            );
          case AiTaskType.expressionTips:
            return const AiGenerationConfig(
              temperature: 0.2,
              maxTokens: 180,
            );
        }
    }
  }
}