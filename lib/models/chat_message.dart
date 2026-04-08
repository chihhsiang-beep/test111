class ChatMessage {
  final String id;
  final String senderName;
  final bool isMe;
  final String originalText; // 中文
  final String translatedText; // 英文
  final DateTime createdAt;
  final bool isLoading;
  final String? extraInfo;
  final bool isExtraLoading;

  ChatMessage({
    required this.id,
    required this.senderName,
    required this.isMe,
    required this.originalText,
    required this.translatedText,
    required this.createdAt,
    this.isLoading = false,
    this.extraInfo,
    this.isExtraLoading = false,
  });

  ChatMessage copyWith({
    String? id,
    String? senderName,
    bool? isMe,
    String? originalText,
    String? translatedText,
    DateTime? createdAt,
    bool? isLoading,
    String? extraInfo,
    bool? isExtraLoading,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderName: senderName ?? this.senderName,
      isMe: isMe ?? this.isMe,
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      createdAt: createdAt ?? this.createdAt,
      isLoading: isLoading ?? this.isLoading,
      extraInfo: extraInfo ?? this.extraInfo,
      isExtraLoading: isExtraLoading ?? this.isExtraLoading,
    );
  }
}