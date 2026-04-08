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
        return 'Gemini（雲端）';
    }
  }

  String get description {
    switch (this) {
      case AiProvider.gemmaLocal:
        return '離線可用，不吃 API 額度，但回覆品質較普通';
      case AiProvider.geminiApi:
        return '回覆品質較好，但需要網路';
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