import 'package:flutter/material.dart';
import 'chat_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('英文學習助手', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGridSection(context, '學習功能', [
              _MenuData('AI 聊天', Icons.chat_bubble_outline, Colors.blue, const ChatPage()),
              _MenuData('詞彙', Icons.abc, Colors.teal, null),
              _MenuData('文法', Icons.spellcheck, Colors.orange, null),
              _MenuData('聽解', Icons.headphones, Colors.redAccent, null),
            ]),
            const SizedBox(height: 30),
            _buildGridSection(context, '其他功能', [
              _MenuData('學習重點', Icons.book_outlined, Colors.indigo, null),
              _MenuData('模擬考', Icons.timer_outlined, Colors.brown, null),
              _MenuData('搜尋試題', Icons.search, Colors.blueGrey, null),
              _MenuData('網站', Icons.public, Colors.green, null),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildGridSection(BuildContext context, String title, List<_MenuData> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 20,
            crossAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => _buildMenuItem(context, items[index]),
        ),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, _MenuData item) {
    return InkWell(
      onTap: () {
        if (item.targetPage != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => item.targetPage!));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.title} 功能開發中')));
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
            ),
            child: Icon(item.icon, color: item.color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(item.title, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _MenuData {
  final String title;
  final IconData icon;
  final Color color;
  final Widget? targetPage;
  _MenuData(this.title, this.icon, this.color, this.targetPage);
}