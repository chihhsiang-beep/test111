import 'package:flutter/material.dart';
import '../models/chat_entry_mode.dart';
import '../pages/chat_page.dart';

class ChatTopicSelectPage extends StatelessWidget {
  const ChatTopicSelectPage({super.key});

  static const List<_TopicItem> _topics = [
    _TopicItem('工作', Icons.work_outline_rounded),
    _TopicItem('吃飯', Icons.restaurant_outlined),
    _TopicItem('旅遊', Icons.flight_takeoff_rounded),
    _TopicItem('遊戲', Icons.sports_esports_outlined),
    _TopicItem('購物', Icons.shopping_bag_outlined),
    _TopicItem('校園', Icons.school_outlined),
    _TopicItem('面試', Icons.badge_outlined),
    _TopicItem('電影', Icons.movie_outlined),
    _TopicItem('交朋友', Icons.people_outline_rounded),
    _TopicItem('醫院', Icons.local_hospital_outlined),
    _TopicItem('天氣', Icons.wb_cloudy_outlined),
    _TopicItem('運動', Icons.fitness_center_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F4F6),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '選擇聊天主題',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '挑一個情境開始練習',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '選一個你今天想練習的主題，聊天室會依照主題和你對話。',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  itemCount: _topics.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.25,
                  ),
                  itemBuilder: (context, index) {
                    final topic = _topics[index];
                    return _TopicCard(
                      title: topic.title,
                      icon: topic.icon,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              entryMode: ChatEntryMode.topicChat,
                              topic: topic.title,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicItem {
  final String title;
  final IconData icon;

  const _TopicItem(this.title, this.icon);
}

class _TopicCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _TopicCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF111827),
                  size: 24,
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '進入此主題聊天',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}