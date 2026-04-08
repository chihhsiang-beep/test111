import 'package:flutter/material.dart';
import '../models/chat_entry_mode.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../services/vocab_database_service.dart';
import '../widgets/message_bubble.dart';

class ChatPage extends StatefulWidget {
  final ChatEntryMode entryMode;
  final String? topic;

  const ChatPage({
    super.key,
    required this.entryMode,
    this.topic,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  //state 變數區
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final Set<String> _favoriteCache = {};
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteCache();
  }

  String _favoriteKey(ChatMessage message) {
    return '${message.originalText}__${message.translatedText}';
  }

  String _sourceModeText() {
    switch (widget.entryMode) {
      case ChatEntryMode.freeChat:
        return 'free_chat';
      case ChatEntryMode.reviewChat:
        return 'review_chat';
      case ChatEntryMode.topicChat:
        return 'topic_chat';
      case ChatEntryMode.modelSelect:
        return 'model_select';
    }
  }

  Future<void> _loadFavoriteCache() async {
    try {
      final rows = await VocabDatabaseService.instance.getFavoriteSentences();

      final keys = rows.map((row) {
        final original = (row['original_text'] ?? '').toString();
        final translated = (row['translated_text'] ?? '').toString();
        return '${original}__${translated}';
      }).toSet();

      if (!mounted) return;

      setState(() {
        _favoriteCache
          ..clear()
          ..addAll(keys);
      });
    } catch (e) {
      debugPrint('_loadFavoriteCache error: $e');
    }
  }

  Future<bool> _toggleFavoriteMessage(ChatMessage message) async {

    if (message.translatedText.trim().isEmpty) {
      return false;
    }

    try {
      final saved = await VocabDatabaseService.instance.toggleFavoriteSentence(
        originalText: message.originalText,
        translatedText: message.translatedText,
        senderName: message.senderName,
        isMe: message.isMe,
        sourceMode: _sourceModeText(),
        topic: widget.topic,
        createdAt: message.createdAt.toIso8601String(),
      );

      final key = _favoriteKey(message);

      if (!mounted) return saved;

      setState(() {
        if (saved) {
          _favoriteCache.add(key);
        } else {
          _favoriteCache.remove(key);
        }
      });

      return saved;
    } catch (e) {
      debugPrint('_toggleFavoriteMessage error: $e');
      return false;
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    _textController.clear();
    setState(() => _isSending = true);

    final myMsg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      senderName: 'Me',
      isMe: true,
      originalText: text,
      translatedText: '',
      createdAt: DateTime.now(),
      isLoading: true,
    );

    setState(() => _messages.add(myMsg));
    _scrollToBottom();

    try {
      final myEn = await _buildMyTranslation(text);
      _updateMessage(myMsg.id, translatedText: myEn, isLoading: false);

      await _generateAmyReply(text);
    } catch (e) {
      _updateMessage(
        myMsg.id,
        translatedText: '發生錯誤，請稍後再試。',
        isLoading: false,
      );
    }

    setState(() => _isSending = false);
  }

  Future<String> _buildMyTranslation(String text) async {
    switch (widget.entryMode) {
      case ChatEntryMode.freeChat:
        return await AIService.translate(text);
      case ChatEntryMode.reviewChat:
        return await AIService.translate(text);
      case ChatEntryMode.topicChat:
        return await AIService.translate(text);
      case ChatEntryMode.modelSelect:
        return await AIService.translate(text);
    }
  }

  Future<void> _generateAmyReply(String userText) async {
    final amyMsg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      senderName: 'Amy',
      isMe: false,
      originalText: '思考中...',
      translatedText: '',
      createdAt: DateTime.now(),
      isLoading: true,
    );

    setState(() => _messages.add(amyMsg));
    _scrollToBottom();

    final context = _messages
        .reversed
        .take(4)
        .toList()
        .reversed
        .map((m) => '${m.senderName}: ${m.originalText}')
        .join('\n');

    String replyZh;

    switch (widget.entryMode) {
      case ChatEntryMode.freeChat:
        replyZh = await AIService.getChineseReply(context, userText);
        break;

      case ChatEntryMode.reviewChat:
        replyZh = await AIService.getChineseReply(
          '$context\n模式：複習聊天，請用較簡單、適合英文學習者的方式回覆。',
          userText,
        );
        break;

      case ChatEntryMode.topicChat:
        replyZh = await AIService.getChineseReply(
          '$context\n目前聊天主題：${widget.topic ?? "一般主題"}，請圍繞此主題回覆。',
          userText,
        );
        break;

      case ChatEntryMode.modelSelect:
        replyZh = await AIService.getChineseReply(context, userText);
        break;
    }

    _updateMessage(amyMsg.id, originalText: replyZh, isLoading: true);

    final replyEn = await AIService.translate(replyZh);

    _updateMessage(
      amyMsg.id,
      translatedText: replyEn,
      isLoading: false,
    );
    _scrollToBottom();
  }

  void _updateMessage(
      String id, {
        String? originalText,
        String? translatedText,
        bool? isLoading,
      }) {
    final index = _messages.indexWhere((m) => m.id == id);
    if (index == -1) return;

    setState(() {
      _messages[index] = _messages[index].copyWith(
        originalText: originalText,
        translatedText: translatedText,
        isLoading: isLoading,
      );
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  String _pageTitle() {
    switch (widget.entryMode) {
      case ChatEntryMode.freeChat:
        return '隨意聊天';
      case ChatEntryMode.reviewChat:
        return '複習聊天';
      case ChatEntryMode.topicChat:
        return widget.topic == null ? '主題聊天' : '${widget.topic}聊天';
      case ChatEntryMode.modelSelect:
        return 'AI 聊天室';
    }
  }

  String _hintText() {
    switch (widget.entryMode) {
      case ChatEntryMode.freeChat:
        return '想聊什麼都可以...';
      case ChatEntryMode.reviewChat:
        return '用剛學過的單字試著聊天...';
      case ChatEntryMode.topicChat:
        return '輸入和${widget.topic ?? "主題"}有關的內容...';
      case ChatEntryMode.modelSelect:
        return '輸入內容...';
    }
  }

  Widget _buildBottomInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _InputToolButton(
            icon: Icons.mic_none_rounded,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('語音功能之後再接'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          _InputToolButton(
            icon: Icons.image_outlined,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('圖片功能之後再接'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          // _InputToolButton(
          //   icon: Icons.bookmark_border_rounded,
          //   onTap: () {
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       const SnackBar(
          //         content: Text('收藏功能之後再接'),
          //         duration: Duration(seconds: 1),
          //       ),
          //     );
          //   },
          // ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(28),
              ),
              child: TextField(
                controller: _textController,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: _hintText(),
                  border: InputBorder.none,
                  hintStyle: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 15,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          _InputToolButton(
            icon: Icons.sentiment_satisfied_alt_outlined,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('表情 / 更多功能之後再接'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF111827),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: _isSending
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTag() {
    String text;
    switch (widget.entryMode) {
      case ChatEntryMode.freeChat:
        text = '隨意聊天';
        break;
      case ChatEntryMode.reviewChat:
        text = '複習聊天';
        break;
      case ChatEntryMode.topicChat:
        text = widget.topic == null ? '主題聊天' : '主題：${widget.topic}';
        break;
      case ChatEntryMode.modelSelect:
        text = '一般聊天';
        break;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(
          _pageTitle(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildModeTag(),
          Expanded(
            child: _messages.isEmpty
                ? const _EmptyChatHint()
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return MessageBubble(
                  message: msg,
                  timeText: _formatTime(msg.createdAt),
                  initiallySaved: _favoriteCache.contains(_favoriteKey(msg)),
                  onToggleFavorite: _toggleFavoriteMessage,
                );
              },
            ),
          ),
          _buildBottomInputArea(),
        ],
      ),
    );
  }
}

class _InputToolButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _InputToolButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        color: const Color(0xFF4B5563),
        size: 24,
      ),
      splashRadius: 22,
    );
  }
}

class _EmptyChatHint extends StatelessWidget {
  const _EmptyChatHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 30,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '開始你的英文練習',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '現在是聊天室頁面，模式已經在前一頁選好了。',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}