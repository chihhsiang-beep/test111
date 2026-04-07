import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final String timeText;

  const MessageBubble({
    super.key,
    required this.message,
    required this.timeText,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _showDetails = false;

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
                          fontWeight: FontWeight.w500,
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
                                  : Icons.translate,
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
                              icon: Icons.copy_rounded,
                              label: '複製英文',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('已複製英文內容'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              isMe: isMe,
                            ),
                          ],
                        ),
                        if (_showDetails) ...[
                          const SizedBox(height: 10),
                          _DetailSection(
                            title: '學習提示',
                            content: isMe
                                ? '上面是你輸入的中文，下面是對應英文。你可以比對字詞順序，熟悉常見句型。'
                                : '上面是 AI 的中文回覆，下面是英文版本。你可以直接拿來模仿口說或對話。',
                            isMe: isMe,
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

class _DetailSection extends StatelessWidget {
  final String title;
  final String content;
  final bool isMe;

  const _DetailSection({
    required this.title,
    required this.content,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isMe ? Colors.white : const Color(0xFF111827);
    final bodyColor = isMe ? Colors.white70 : const Color(0xFF6B7280);
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
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              color: bodyColor,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}