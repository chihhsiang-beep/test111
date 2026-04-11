import 'package:flutter/material.dart';
import '../models/chat_entry_mode.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../services/vocab_database_service.dart';
import '../widgets/message_bubble.dart';
import 'favorite_sentences_page.dart';

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
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final Set<String> _favoriteCache = {};

  bool _isSending = false;
  bool _isLoadingChatHistory = true;
  int? _sessionId;

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initPage() async {
    await _loadFavoriteCache();
    await _initChatSession();
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

  String _buildSessionKey() {
    switch (widget.entryMode) {
      case ChatEntryMode.freeChat:
        return 'chat_free_chat';
      case ChatEntryMode.reviewChat:
        return 'chat_review_chat';
      case ChatEntryMode.topicChat:
        final safeTopic =
        (widget.topic ?? 'default').trim().replaceAll(RegExp(r'\s+'), '_');
        return 'chat_topic_chat_$safeTopic';
      case ChatEntryMode.modelSelect:
        return 'chat_model_select';
    }
  }

  Future<void> _initChatSession() async {
    try {
      final sessionId = await VocabDatabaseService.instance.getOrCreateChatSession(
        sessionKey: _buildSessionKey(),
        mode: _sourceModeText(),
        title: _pageTitle(),
      );

      final rows = await VocabDatabaseService.instance.getChatMessages(sessionId);

      final restoredMessages = rows.map(_mapRowToChatMessage).toList();

      if (!mounted) return;

      setState(() {
        _sessionId = sessionId;
        _messages
          ..clear()
          ..addAll(restoredMessages);
        _isLoadingChatHistory = false;
      });

      _scrollToBottom(jump: true);
    } catch (e) {
      debugPrint('_initChatSession error: $e');

      if (!mounted) return;
      setState(() {
        _isLoadingChatHistory = false;
      });
    }
  }

  ChatMessage _mapRowToChatMessage(Map<String, dynamic> row) {
    final role = (row['role'] ?? '').toString();
    final isUser = role == 'user';

    return ChatMessage(
      id: (row['id'] ?? '').toString(),
      senderName: isUser ? 'Me' : 'Amy',
      isMe: isUser,
      originalText: (row['message'] ?? '').toString(),
      translatedText: (row['translated_text'] ?? '').toString(),
      createdAt: DateTime.tryParse((row['created_at'] ?? '').toString()) ??
          DateTime.now(),
      isLoading: false,
    );
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
    if (text.isEmpty || _isSending || _sessionId == null) return;

    _textController.clear();
    setState(() => _isSending = true);

    try {
      final userMessageId =
      await VocabDatabaseService.instance.insertChatMessage(
        sessionId: _sessionId!,
        role: 'user',
        message: text,
        translatedText: '',
      );

      final myMsg = ChatMessage(
        id: userMessageId.toString(),
        senderName: 'Me',
        isMe: true,
        originalText: text,
        translatedText: '',
        createdAt: DateTime.now(),
        isLoading: true,
      );

      setState(() => _messages.add(myMsg));
      _scrollToBottom();

      final myEn = await _buildMyTranslation(text);

      _updateMessage(
        myMsg.id,
        translatedText: myEn,
        isLoading: false,
      );

      await VocabDatabaseService.instance.updateChatMessage(
        messageId: userMessageId,
        translatedText: myEn,
      );

      await _generateAmyReply(text);
    } catch (e) {
      debugPrint('_sendMessage error: $e');
    }

    if (!mounted) return;
    setState(() => _isSending = false);
  }

  Future<String> _buildMyTranslation(String text) async {
    switch (widget.entryMode) {
      case ChatEntryMode.freeChat:
        return await AIService.translateToEnglish(text);
      case ChatEntryMode.reviewChat:
        return await AIService.translateToEnglish(text);
      case ChatEntryMode.topicChat:
        return await AIService.translateToEnglish(text);
      case ChatEntryMode.modelSelect:
        return await AIService.translateToEnglish(text);
    }
  }

  Future<void> _generateAmyReply(String userText) async {
    if (_sessionId == null) return;

    final tempId = 'temp_${DateTime.now().microsecondsSinceEpoch}';

    final amyLoadingMsg = ChatMessage(
      id: tempId,
      senderName: 'Amy',
      isMe: false,
      originalText: '思考中...',
      translatedText: '',
      createdAt: DateTime.now(),
      isLoading: true,
    );

    setState(() => _messages.add(amyLoadingMsg));
    _scrollToBottom();

    try {
      final context = _messages
          .where((m) => m.originalText != '思考中...')
          .toList()
          .reversed
          .take(6)
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
            '$context\n模式：複習聊天，請用較簡單、適合英文學習者的方式回覆。請一定使用繁體中文回覆，禁止只用英文回答。',
            userText,
          );
          break;

        case ChatEntryMode.topicChat:
          replyZh = await AIService.getChineseReply(
            '$context\n目前聊天主題：${widget.topic ?? "一般主題"}，請圍繞此主題回覆。請一定使用繁體中文回覆，禁止只用英文回答。',
            userText,
          );
          break;

        case ChatEntryMode.modelSelect:
          replyZh = await AIService.getChineseReply(context, userText);
          break;
      }

      final assistantMessageId =
      await VocabDatabaseService.instance.insertChatMessage(
        sessionId: _sessionId!,
        role: 'assistant',
        message: replyZh,
        translatedText: '',
      );

      final assistantMsg = ChatMessage(
        id: assistantMessageId.toString(),
        senderName: 'Amy',
        isMe: false,
        originalText: replyZh,
        translatedText: '',
        createdAt: DateTime.now(),
        isLoading: true,
      );

      _replaceMessage(tempId, assistantMsg);

      final replyEn = await AIService.translateToEnglish(replyZh);

      _updateMessage(
        assistantMsg.id,
        translatedText: replyEn,
        isLoading: false,
      );

      await VocabDatabaseService.instance.updateChatMessage(
        messageId: assistantMessageId,
        translatedText: replyEn,
      );

      _scrollToBottom();
    } catch (e) {
      debugPrint('_generateAmyReply error: $e');

      _updateMessage(
        tempId,
        originalText: '發生錯誤，請稍後再試。',
        translatedText: '',
        isLoading: false,
      );
    }
  }

  void _replaceMessage(String oldId, ChatMessage newMessage) {
    final index = _messages.indexWhere((m) => m.id == oldId);
    if (index == -1) return;

    setState(() {
      _messages[index] = newMessage;
    });
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

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final target = _scrollController.position.maxScrollExtent;

      if (jump) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
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

  Future<void> _clearCurrentChat() async {
    try {
      await VocabDatabaseService.instance.clearChatSessionByKey(
        _buildSessionKey(),
      );

      if (!mounted) return;

      setState(() {
        _messages.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('聊天室已清空'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      debugPrint('_clearCurrentChat error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('清空失敗'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _handleMoreTap(ChatMessage message) async {
    final index = _messages.indexWhere((m) => m.id == message.id);
    if (index == -1) return;

    final current = _messages[index];

    if (current.extraInfo != null && current.extraInfo!.trim().isNotEmpty) {
      setState(() {
        _messages[index] = current.copyWith(
          isExtraLoading: false,
        );
      });
      return;
    }

    setState(() {
      _messages[index] = current.copyWith(
        isExtraLoading: true,
      );
    });

    try {
      final result = await AIService.getExpressionTips(
        message.translatedText.trim().isNotEmpty
            ? message.translatedText
            : message.originalText,
      );

      debugPrint('MORE RAW RESULT = $result');

      if (!mounted) return;

      setState(() {
        _messages[index] = _messages[index].copyWith(
          extraInfo: result,
          isExtraLoading: false,
        );
      });
    } catch (e) {
      debugPrint('_handleMoreTap error: $e');

      if (!mounted) return;

      setState(() {
        _messages[index] = _messages[index].copyWith(
          extraInfo:
          'Alternative 1: Failed to load.\n'
              'Alternative 2: Please try again.\n'
              'Note: No data available.',
          isExtraLoading: false,
        );
      });
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
          _InputToolButton(
            icon: Icons.bookmark_outline_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FavoriteSentencesPage(
                    sourceMode: _sourceModeText(),
                    topic: widget.topic,
                  ),
                ),
              );
            },
          ),
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
    if (_isLoadingChatHistory) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FB),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
        actions: [
          IconButton(
            onPressed: _clearCurrentChat,
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: '清空聊天室',
          ),
        ],
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
                  onTapMore: _handleMoreTap,
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