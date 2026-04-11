enum AiProvider {
  gemmaLocal,
  geminiApi,
}

extension AiProviderX on AiProvider {
  String get storageValue {
    switch (this) {
      case AiProvider.gemmaLocal:
        return 'gemma_local';
      case AiProvider.geminiApi:
        return 'gemini_api';
    }
  }

  String get label {
    switch (this) {
      case AiProvider.gemmaLocal:
        return 'Gemma 2B（本地）';
      case AiProvider.geminiApi:
        return 'Gemma 4 31B（雲端）';
    }
  }

  String get description {
    switch (this) {
      case AiProvider.gemmaLocal:
        return '離線可用，不吃 API 額度，但較適合短 prompt';
      case AiProvider.geminiApi:
        return '回覆品質較好，適合較完整規則與結構化輸出';
    }
  }

  bool get prefersSimplePrompt {
    switch (this) {
      case AiProvider.gemmaLocal:
        return true;
      case AiProvider.geminiApi:
        return false;
    }
  }

  bool get supportsStrictJsonPrompt {
    switch (this) {
      case AiProvider.gemmaLocal:
        return false;
      case AiProvider.geminiApi:
        return true;
    }
  }

  static AiProvider fromStorageValue(String? value) {
    switch (value) {
      case 'gemini_api':
        return AiProvider.geminiApi;
      case 'gemma_local':
      default:
        return AiProvider.gemmaLocal;
    }
  }
}