import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final String timeText;
  final Future<bool> Function(ChatMessage message)? onToggleFavorite;
  final bool initiallySaved;
  final Future<void> Function(ChatMessage message)? onTapMore;
  const MessageBubble({
    super.key,
    required this.message,
    required this.timeText,
    this.onToggleFavorite,
    this.initiallySaved = false,
    this.onTapMore,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _showDetails = false;
  late bool _isSaved;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.initiallySaved;
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isMe = message.isMe;

    final bubbleColor = isMe ? const Color(0xFF111827) : Colors.white;
    final mainTextColor = isMe ? Colors.white : const Color(0xFF111827);
    final subTextColor = isMe ? Colors.white70 : const Color(0xFF6B7280);


    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(22),
      topRight: const Radius.circular(22),
      bottomLeft: Radius.circular(isMe ? 22 : 8),
      bottomRight: Radius.circular(isMe ? 8 : 22),
    );

    final hasTranslation = message.translatedText.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Column(
        crossAxisAlignment:
        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 4),
              child: Text(
                message.senderName,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Row(
            mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isMe) ...[
                Text(
                  widget.timeText,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: borderRadius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.originalText,
                        style: TextStyle(
                          fontSize: 16,
                          color: mainTextColor,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (message.isLoading)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isMe ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '生成中...',
                              style: TextStyle(
                                fontSize: 13,
                                color: subTextColor,
                              ),
                            ),
                          ],
                        )
                      else if (hasTranslation) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Colors.white.withOpacity(0.10)
                                : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isMe
                                  ? Colors.white.withOpacity(0.12)
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Text(
                            message.translatedText,
                            style: TextStyle(
                              fontSize: 13,
                              color: subTextColor,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _BubbleActionButton(
                              icon: _showDetails
                                  ? Icons.expand_less
                                  : Icons.auto_awesome_outlined,
                              label: _showDetails ? '收合' : '更多',
                              onTap: () async {
                                if (_showDetails) {
                                  setState(() {
                                    _showDetails = false;
                                  });
                                  return;
                                }

                                setState(() {
                                  _showDetails = true;
                                });

                                if (widget.onTapMore != null &&
                                    (message.extraInfo == null || message.extraInfo!.trim().isEmpty)) {
                                  await widget.onTapMore!(message);
                                }
                              },
                              isMe: isMe,
                            ),
                            const SizedBox(width: 8),
                            _BubbleActionButton(
                              icon: _isSaved
                                  ? Icons.bookmark
                                  : Icons.bookmark_border_rounded,
                              label: _isSaved ? '已收藏' : '收藏',
                              onTap: () async {
                                if (widget.onToggleFavorite == null) return;

                                final saved = await widget.onToggleFavorite!(widget.message);

                                if (!mounted) return;

                                setState(() {
                                  _isSaved = saved;
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(saved ? '已加入收藏' : '已取消收藏'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                              isMe: isMe,
                            ),
                          ],
                        ),
                        if (_showDetails) ...[
                          const SizedBox(height: 10),
                          _ExtraLearningPanel(
                            isMe: isMe,
                            titleColor: mainTextColor,
                            bodyColor: subTextColor,
                            extraInfo: message.extraInfo,
                            isLoading: message.isExtraLoading,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              if (!isMe) ...[
                const SizedBox(width: 6),
                Text(
                  widget.timeText,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _BubbleActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isMe;

  const _BubbleActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isMe ? Colors.white70 : const Color(0xFF4B5563);
    final bg = isMe
        ? Colors.white.withOpacity(0.10)
        : const Color(0xFFF3F4F6);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExtraLearningPanel extends StatelessWidget {
  final bool isMe;
  final Color titleColor;
  final Color bodyColor;
  final String? extraInfo;
  final bool isLoading;

  const _ExtraLearningPanel({
    required this.isMe,
    required this.titleColor,
    required this.bodyColor,
    required this.extraInfo,
    required this.isLoading,
  });

  Map<String, String> _parseExtraInfo(String text) {
    String alt1 = '';
    String alt2 = '';
    String note = '';

    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);

    for (final line in lines) {
      if (line.startsWith('Alternative 1:')) {
        alt1 = line.replaceFirst('Alternative 1:', '').trim();
      } else if (line.startsWith('Alternative 2:')) {
        alt2 = line.replaceFirst('Alternative 2:', '').trim();
      } else if (line.startsWith('Note:')) {
        note = line.replaceFirst('Note:', '').trim();
      }

      // 相容舊格式
      else if (line.startsWith('Example:') && alt1.isEmpty) {
        alt1 = line.replaceFirst('Example:', '').trim();
      } else if (line.startsWith('Usage:') && note.isEmpty) {
        note = line.replaceFirst('Usage:', '').trim();
      }
    }

    if (alt1.isEmpty) alt1 = 'No alternative available.';
    if (alt2.isEmpty) alt2 = 'No alternative available.';
    if (note.isEmpty) note = 'No note available.';

    return {
      'alt1': alt1,
      'alt2': alt2,
      'note': note,
    };
  }

  @override
  Widget build(BuildContext context) {
    final bg = isMe
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFF9FAFB);

    if (isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: bodyColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '載入中...',
              style: TextStyle(
                color: bodyColor,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final raw = extraInfo?.trim() ?? '';
    final parsed = _parseExtraInfo(raw);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '其他說法 1',
            style: TextStyle(
              color: titleColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            parsed['alt1']!,
            style: TextStyle(
              color: bodyColor,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '其他說法 2',
            style: TextStyle(
              color: titleColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            parsed['alt2']!,
            style: TextStyle(
              color: bodyColor,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '小提示',
            style: TextStyle(
              color: titleColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            parsed['note']!,
            style: TextStyle(
              color: bodyColor,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}