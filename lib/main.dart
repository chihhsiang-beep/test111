import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English Chat Learning',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        useMaterial3: true,
      ),
      home: const ChatPage(),
    );
  }
}

class ChatMessage {
  final String id;
  final String senderName;
  final bool isMe;
  final String originalText; // 中文
  final String translatedText; // 英文
  final DateTime createdAt;
  final bool isLoading;

  ChatMessage({
    required this.id,
    required this.senderName,
    required this.isMe,
    required this.originalText,
    required this.translatedText,
    required this.createdAt,
    this.isLoading = false,
  });

  ChatMessage copyWith({
    String? id,
    String? senderName,
    bool? isMe,
    String? originalText,
    String? translatedText,
    DateTime? createdAt,
    bool? isLoading,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderName: senderName ?? this.senderName,
      isMe: isMe ?? this.isMe,
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      createdAt: createdAt ?? this.createdAt,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const String _ollamaUrl = 'http://localhost:11434/api/generate';
  static const String _modelName = 'gemma2:2b';

  bool _isSending = false;

  final List<ChatMessage> _messages = [
    ChatMessage(
      id: '1',
      senderName: 'Amy',
      isMe: false,
      originalText: '你好，今天過得怎麼樣？',
      translatedText: 'Hi, how was your day today?',
      createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
    ),
    ChatMessage(
      id: '2',
      senderName: 'Me',
      isMe: true,
      originalText: '我今天去圖書館看書。',
      translatedText: 'I went to the library to study today.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 6)),
    ),
    ChatMessage(
      id: '3',
      senderName: 'Amy',
      isMe: false,
      originalText: '聽起來很充實！',
      translatedText: 'That sounds productive!',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    _textController.clear();
    setState(() {
      _isSending = true;
    });

    final myMessage = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      senderName: 'Me',
      isMe: true,
      originalText: text,
      translatedText: '',
      createdAt: DateTime.now(),
      isLoading: true,
    );

    setState(() {
      _messages.add(myMessage);
    });
    _scrollToBottom();

    final myEnglish = await _translateToEnglish(text);
    _updateMessage(
      myMessage.id,
      translatedText: myEnglish,
      isLoading: false,
    );

    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 300));
    await _generateAiReply(userText: text);

    setState(() {
      _isSending = false;
    });

    _scrollToBottom();
  }

  Future<void> _generateAiReply({required String userText}) async {
    final aiMessage = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      senderName: 'Amy',
      isMe: false,
      originalText: '思考中...',
      translatedText: '',
      createdAt: DateTime.now(),
      isLoading: true,
    );

    setState(() {
      _messages.add(aiMessage);
    });
    _scrollToBottom();

    final replyZh = await _generateChineseReply(userText);

    _updateMessage(
      aiMessage.id,
      originalText: replyZh,
      translatedText: '',
      isLoading: true,
    );
    _scrollToBottom();

    final replyEn = await _translateToEnglish(replyZh);

    _updateMessage(
      aiMessage.id,
      translatedText: replyEn,
      isLoading: false,
    );
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

  String _buildConversationContext({int limit = 6}) {
    final recent = _messages.length <= limit
        ? _messages
        : _messages.sublist(_messages.length - limit);

    final buffer = StringBuffer();

    for (final msg in recent) {
      final role = msg.isMe ? '使用者' : 'Amy';
      buffer.writeln('$role: ${msg.originalText}');
    }

    return buffer.toString().trim();
  }

  Future<String> _generateChineseReply(String userText) async {
    final context = _buildConversationContext();

    final prompt = '''
你是一個名字叫 Amy 的英文學習聊天夥伴。

任務：
1. 根據聊天上下文，自然回覆使用者。
2. 只用繁體中文回覆。
3. 語氣自然、有人味、像真的聊天，不要像機器翻譯。
4. 回覆長度控制在 1 到 3 句。
5. 不要列點，不要加標題，不要解釋你是 AI。
6. 若使用者提到敏感政治議題，也只做正常對話回應，不要空泛敷衍。
7. 不要輸出英文，不要輸出多餘說明。

聊天上下文：
$context

最新使用者訊息：
$userText

請直接輸出 Amy 的中文回覆：
''';

    final result = await _callOllama(prompt);
    if (result.startsWith('錯誤：')) {
      return result;
    }
    return result;
  }

  Future<String> _translateToEnglish(String text) async {
    final prompt = '''
你是一個專業的中翻英翻譯助手。

規則：
1. 請把下面的繁體中文翻譯成自然、道地、簡潔的英文。
2. 只輸出英文翻譯本身。
3. 不要解釋，不要加引號，不要保留中文。

中文：
$text
''';

    final result = await _callOllama(prompt);
    if (result.startsWith('錯誤：')) {
      return result;
    }
    return result;
  }

  Future<String> _callOllama(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_ollamaUrl),
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _modelName,
          'prompt': prompt,
          'stream': false,
          'options': {
            'temperature': 0.8,
          },
        }),
      );

      if (response.statusCode != 200) {
        return '錯誤：Ollama 連線失敗 (${response.statusCode})';
      }

      final data = jsonDecode(response.body);
      final text = (data['response'] ?? '').toString().trim();

      if (text.isEmpty) {
        return '錯誤：模型沒有回傳內容';
      }

      return text;
    } catch (e) {
      return '錯誤：請檢查 Ollama 是否已開啟';
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

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
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '英文學習聊天室',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 2),
            Text(
              '中文自動翻英文',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.menu_book_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFEAF2FF),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 18, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '每則訊息會顯示：上方中文，下方英文翻譯',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 12),
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
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _textController,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        decoration: const InputDecoration(
                          hintText: '輸入中文，例如：我今天去圖書館看書。',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: FilledButton(
                      onPressed: _isSending ? null : _sendMessage,
                      style: FilledButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                      ),
                      child: _isSending
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.send),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    final bgColor = message.isMe ? const Color(0xFFDCEBFF) : Colors.white;
    final borderColor =
    message.isMe ? const Color(0xFFB7D3FF) : const Color(0xFFE5E7EB);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment:
        message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 6, right: 6),
            child: Text(
              message.senderName,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ),
          Row(
            mainAxisAlignment:
            message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x11000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.originalText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      if (message.isLoading)
                        const Row(
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '處理中...',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          message.translatedText,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeText,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}