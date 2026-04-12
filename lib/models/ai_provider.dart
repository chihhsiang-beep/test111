enum AiProvider {
  gemma2Local,
  gemma4Local,
  qwenLocal,
  geminiApi,
}

extension AiProviderX on AiProvider {
  String get storageValue {
    switch (this) {
      case AiProvider.gemma2Local:
        return 'gemma2_local';
      case AiProvider.gemma4Local:
        return 'gemma4_local';
      case AiProvider.qwenLocal:
        return 'qwen_local';
      case AiProvider.geminiApi:
        return 'gemini_api';
    }
  }

  String get label {
    switch (this) {
      case AiProvider.gemma2Local:
        return 'Gemma 2B（本地）';
      case AiProvider.gemma4Local:
        return 'Gemma 4 E2B（本地）';
      case AiProvider.qwenLocal:
        return 'Qwen 2.5（本地）';
      case AiProvider.geminiApi:
        return 'Gemma 4 31B（雲端）';
    }
  }

  String get description {
    switch (this) {
      case AiProvider.gemma2Local:
        return '離線可用，速度快，適合短 prompt';
      case AiProvider.gemma4Local:
        return '離線可用，品質比 Gemma 2B 更好';
      case AiProvider.qwenLocal:
        return '離線可用，中文表現通常較好';
      case AiProvider.geminiApi:
        return '雲端模型，適合較完整規則與結構化輸出';
    }
  }

  bool get prefersSimplePrompt {
    switch (this) {
      case AiProvider.gemma2Local:
        return true;
      case AiProvider.gemma4Local:
        return false;
      case AiProvider.qwenLocal:
        return false;
      case AiProvider.geminiApi:
        return false;
    }
  }

  bool get supportsStrictJsonPrompt {
    switch (this) {
      case AiProvider.gemma2Local:
        return false;
      case AiProvider.gemma4Local:
        return true;
      case AiProvider.qwenLocal:
        return true;
      case AiProvider.geminiApi:
        return true;
    }
  }

  static AiProvider fromStorageValue(String? value) {
    switch (value) {
      case 'gemma4_local':
        return AiProvider.gemma4Local;
      case 'qwen_local':
        return AiProvider.qwenLocal;
      case 'gemini_api':
        return AiProvider.geminiApi;
      case 'gemma2_local':
      default:
        return AiProvider.gemma2Local;
    }
  }
}