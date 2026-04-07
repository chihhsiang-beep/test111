import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../widgets/menu_icon_button.dart';
import '../widgets/message_bubble.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

enum ChatMode {
  chat,
  translate,
  grammar,
  speak,
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _isSending = false;
  ChatMode _selectedMode = ChatMode.chat;

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
    switch (_selectedMode) {
      case ChatMode.chat:
        return await AIService.translate(text);
      case ChatMode.translate:
        return await AIService.translate(text);
      case ChatMode.grammar:
        final translated = await AIService.translate(text);
        return '文法修正版：\n$translated';
      case ChatMode.speak:
        final translated = await AIService.translate(text);
        return '口語版：\n$translated';
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
        .take(3)
        .toList()
        .reversed
        .map((m) => '${m.senderName}: ${m.originalText}')
        .join('\n');

    String replyZh;
    switch (_selectedMode) {
      case ChatMode.chat:
        replyZh = await AIService.getChineseReply(context, userText);
        break;
      case ChatMode.translate:
        replyZh = '以下是你的內容翻譯與簡單說明。';
        break;
      case ChatMode.grammar:
        replyZh = '我幫你把句子修得更自然了。';
        break;
      case ChatMode.speak:
        replyZh = '我幫你轉成比較適合口說的說法。';
        break;
    }

    _updateMessage(amyMsg.id, originalText: replyZh, isLoading: true);

    String replyEn;
    switch (_selectedMode) {
      case ChatMode.chat:
        replyEn = await AIService.translate(replyZh);
        break;
      case ChatMode.translate:
        replyEn = await AIService.translate(userText);
        break;
      case ChatMode.grammar:
        replyEn = await AIService.translate(userText);
        break;
      case ChatMode.speak:
        replyEn = await AIService.translate(userText);
        break;
    }

    _updateMessage(amyMsg.id, translatedText: replyEn, isLoading: false);
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

  String _modeHintText() {
    switch (_selectedMode) {
      case ChatMode.chat:
        return '一般聊天 / 中英對照';
      case ChatMode.translate:
        return '輸入中文，幫你翻成英文';
      case ChatMode.grammar:
        return '輸入句子，偏向文法修正';
      case ChatMode.speak:
        return '輸入句子，偏向自然口說';
    }
  }

  Widget _buildModeBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          MenuIconButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: '聊天',
            selected: _selectedMode == ChatMode.chat,
            onTap: () {
              setState(() => _selectedMode = ChatMode.chat);
            },
          ),
          const SizedBox(width: 10),
          MenuIconButton(
            icon: Icons.translate_rounded,
            label: '翻譯',
            selected: _selectedMode == ChatMode.translate,
            onTap: () {
              setState(() => _selectedMode = ChatMode.translate);
            },
          ),
          const SizedBox(width: 10),
          MenuIconButton(
            icon: Icons.spellcheck_rounded,
            label: '文法',
            selected: _selectedMode == ChatMode.grammar,
            onTap: () {
              setState(() => _selectedMode = ChatMode.grammar);
            },
          ),
          const SizedBox(width: 10),
          MenuIconButton(
            icon: Icons.record_voice_over_rounded,
            label: '口說',
            selected: _selectedMode == ChatMode.speak,
            onTap: () {
              setState(() => _selectedMode = ChatMode.speak);
            },
          ),
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
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _modeHintText(),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Row(
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
                    minLines: 1,
                    maxLines: 4,
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
                radius: 24,
                backgroundColor:
                _isSending ? Colors.grey : const Color(0xFF111827),
                child: IconButton(
                  icon: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: _isSending ? null : _sendMessage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'AI 聊天室',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildModeBar(),
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
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
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
            const Text(
              '你可以用聊天、翻譯、文法修正或口說模式來練習。',
              textAlign: TextAlign.center,
              style: TextStyle(
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