import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isSending = false;

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    _textController.clear();
    setState(() => _isSending = true);

    final myMsg = ChatMessage(
      id: DateTime.now().toString(),
      senderName: 'Me',
      isMe: true,
      originalText: text,
      translatedText: '',
      createdAt: DateTime.now(),
      isLoading: true,
    );

    setState(() => _messages.add(myMsg));
    _scrollToBottom();

    // 1. 翻譯我的訊息
    final myEn = await AIService.translate(text);
    _updateMessage(myMsg.id, translatedText: myEn, isLoading: false);

    // 2. 生成 Amy 回覆
    await _generateAmyReply(text);

    setState(() => _isSending = false);
  }

  Future<void> _generateAmyReply(String userText) async {
    final amyMsg = ChatMessage(
      id: DateTime.now().toString(),
      senderName: 'Amy',
      isMe: false,
      originalText: '思考中...',
      translatedText: '',
      createdAt: DateTime.now(),
      isLoading: true,
    );

    setState(() => _messages.add(amyMsg));
    _scrollToBottom();

    // 取得上下文 (取最後三條)
    final context = _messages.take(3).map((m) => "${m.senderName}: ${m.originalText}").join("\n");

    final replyZh = await AIService.getChineseReply(context, userText);
    _updateMessage(amyMsg.id, originalText: replyZh, isLoading: true);

    final replyEn = await AIService.translate(replyZh);
    _updateMessage(amyMsg.id, translatedText: replyEn, isLoading: false);
    _scrollToBottom();
  }

  void _updateMessage(String id, {String? originalText, String? translatedText, bool? isLoading}) {
    final index = _messages.indexWhere((m) => m.id == id);
    if (index != -1) {
      setState(() {
        _messages[index] = _messages[index].copyWith(
          originalText: originalText,
          translatedText: translatedText,
          isLoading: isLoading,
        );
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB), // 輕微的灰色背景讓氣泡更明顯
      appBar: AppBar(
        title: const Text('AI 聊天室', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return MessageBubble(
                  message: msg,
                  timeText: _formatTime(msg.createdAt),
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: '輸入中文...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: _isSending ? Colors.grey : Colors.blue,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

// --- 美化後的 MessageBubble 元件 ---
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String timeText;

  const MessageBubble({
    super.key,
    required this.message,
    required this.timeText,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final bubbleColor = isMe ? const Color(0xFF007AFF) : Colors.white;
    final textColor = isMe ? Colors.white : Colors.black87;
    final subTextColor = isMe ? Colors.white70 : Colors.black54;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Amy 的名字
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(message.senderName, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ),

          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isMe) ...[
                Text(timeText, style: const TextStyle(fontSize: 10, color: Colors.black38)),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 5),
                      bottomRight: Radius.circular(isMe ? 5 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.originalText,
                        style: TextStyle(fontSize: 16, color: textColor, height: 1.4),
                      ),
                      const SizedBox(height: 6),
                      if (message.isLoading && !isMe)
                        const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      else
                        Text(
                          message.translatedText,
                          style: TextStyle(fontSize: 13, color: subTextColor, height: 1.4),
                        ),
                    ],
                  ),
                ),
              ),
              if (!isMe) ...[
                const SizedBox(width: 6),
                Text(timeText, style: const TextStyle(fontSize: 10, color: Colors.black38)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}