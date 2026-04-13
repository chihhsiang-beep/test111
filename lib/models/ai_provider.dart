enum AiProvider {
  local,
  cloud,
}

extension AiProviderX on AiProvider {
  String get storageValue {
    switch (this) {
      case AiProvider.local:
        return 'local';
      case AiProvider.cloud:
        return 'cloud';
    }
  }

  String get label {
    switch (this) {
      case AiProvider.local:
        return '本地模型';
      case AiProvider.cloud:
        return '雲端模型';
    }
  }

  String get description {
    switch (this) {
      case AiProvider.local:
        return '聊天、翻譯、更多由本地模型分工完成';
      case AiProvider.cloud:
        return '保留給雲端模型使用';
    }
  }

  static AiProvider fromStorageValue(String? value) {
    switch (value) {
      case 'cloud':
        return AiProvider.cloud;
      case 'local':
      default:
        return AiProvider.local;
    }
  }
}