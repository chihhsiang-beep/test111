import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final String timeText;
  final Future<bool> Function(ChatMessage message)? onToggleFavorite;
  final bool initiallySaved;

  const MessageBubble({
    super.key,
    required this.message,
    required this.timeText,
    this.onToggleFavorite,
    this.initiallySaved = false,
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
    final extraContent = _buildExtraLearningContent(
      originalText: message.originalText,
      translatedText: message.translatedText,
      isMe: isMe,
    );

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
                              onTap: () {
                                setState(() {
                                  _showDetails = !_showDetails;
                                });
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
                            alt1: extraContent.alt1,
                            alt2: extraContent.alt2,
                            grammarTip: extraContent.grammarTip,
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

  _ExtraContent _buildExtraLearningContent({
    required String originalText,
    required String translatedText,
    required bool isMe,
  }) {
    final en = translatedText.trim().toLowerCase();

    if (en.contains('what do you like to eat')) {
      return _ExtraContent(
        alt1: 'What kinds of food do you enjoy?',
        alt2: 'What food do you usually like to eat?',
        grammarTip:
        'like to eat 表示「喜歡吃……」。\n'
            '如果要表達「我是個很愛吃某種東西的人」，可以說：\n'
            "I'm a big fan of spicy food.\n"
            "I'm a dessert person.\n"
            "I'm a girl who loves desserts.",
      );
    }

    if (en.contains('i like') || en.contains('i enjoy')) {
      return _ExtraContent(
        alt1: 'I really enjoy that kind of food.',
        alt2: 'That is one of my favorite things to eat.',
        grammarTip:
        'I like... / I enjoy... 都可以用來表達喜好。\n'
            '如果要加強語氣，可以說：\n'
            "I really like ...\n"
            "I'm a ... person.\n"
            '例如：\n'
            "I'm a coffee person.\n"
            "I'm a boy who loves ramen.",
      );
    }

    return _ExtraContent(
      alt1: 'You can also say this in a more casual way.',
      alt2: 'There are often several natural ways to express the same idea.',
      grammarTip:
      '同一句中文常常可以有不同英文說法。\n'
          '你可以注意：\n'
          '1. 動詞有沒有換掉\n'
          '2. 語氣是不是更口語\n'
          '3. 有沒有使用固定句型\n'
          '例如：\n'
          "I'm a ... person.\n"
          "I'm someone who likes ...",
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
  final String alt1;
  final String alt2;
  final String grammarTip;

  const _ExtraLearningPanel({
    required this.isMe,
    required this.titleColor,
    required this.bodyColor,
    required this.alt1,
    required this.alt2,
    required this.grammarTip,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isMe
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFF9FAFB);

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
            '其他說法',
            style: TextStyle(
              color: titleColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '1. $alt1',
            style: TextStyle(
              color: bodyColor,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '2. $alt2',
            style: TextStyle(
              color: bodyColor,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '文法 / 用法',
            style: TextStyle(
              color: titleColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            grammarTip,
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

class _ExtraContent {
  final String alt1;
  final String alt2;
  final String grammarTip;

  _ExtraContent({
    required this.alt1,
    required this.alt2,
    required this.grammarTip,
  });
}