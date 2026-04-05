import 'package:flutter/material.dart';
import 'chat_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // 稍微帶一點灰的背景，突顯卡片
      appBar: AppBar(
        backgroundColor: Colors.transparent, // 透明 AppBar
        elevation: 0,
        title: const Text(
          '我的學習主頁',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
      ),

      body: GridView.count(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20), // 調整邊距
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 0.85, // 調整卡片比例，讓它稍微高一點
        children: [
          // --- 卡片 1：AI 聊天室 (使用圖片) ---
          _ImageCard(
            title: 'AI 聊天室',
            subtitle: '',
            imagePath: 'assets/Starlit Conversations.png', // 填入你的圖片路徑
            icon: Icons.chat_bubble_outline,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatPage())),
          ),

          // --- 卡片 2：單字練習 (使用圖片) ---
          const _ImageCard(
            title: '單字複習',
            subtitle: '',
            imagePath: 'assets/Constellation of Words.png', // 填入你的圖片路徑
            icon: Icons.abc,
          ),

          // --- 卡片 3：文法重點 (使用顏色) ---
          const _ImageCard(
            title: '文法重點',
            subtitle: 'Completed!',
            color: Color(0xFFF28482), // 如果沒有圖片，可以用顏色代替
            icon: Icons.edit_note,
            isCompleted: true,
          ),

          // --- 卡片 4：聽力練習 (使用圖片) ---
          const _ImageCard(
            title: '聽力挑戰',
            subtitle: '中級聽解',
            imagePath: 'assets/listening_bg.jpg', // 填入你的圖片路徑
            icon: Icons.headphones,
          ),
        ],
      ),

      // 底部導覽列保持不變
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFE07A5F),
        elevation: 4,
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 10,
      color: Colors.white,
      elevation: 10,
      child: SizedBox(
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: const Icon(Icons.home, color: Color(0xFFE07A5F), size: 28), onPressed: () {}),
            IconButton(icon: const Icon(Icons.search, color: Colors.black45, size: 28), onPressed: () {}),
            const SizedBox(width: 50),
            IconButton(icon: const Icon(Icons.person_outline, color: Colors.black45, size: 28), onPressed: () {}),
            IconButton(icon: const Icon(Icons.logout, color: Colors.black45, size: 28), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}

// --- 升級版：支援圖片的卡片元件 ---
class _ImageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? imagePath; // 圖片路徑 (選填)
  final Color? color;     // 顏色 (選填，若無圖片時使用)
  final bool isCompleted;
  final VoidCallback? onTap;

  const _ImageCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.imagePath,
    this.color,
    this.isCompleted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: color ?? Colors.grey.shade300, // 預設底色
          // --- 核心：設置背景圖片 ---
          image: imagePath != null
              ? DecorationImage(
            image: AssetImage(imagePath!),
            fit: BoxFit.cover, // 圖片鋪滿
            // 完成時加上灰色濾鏡
            colorFilter: isCompleted
                ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                : null,
          )
              : null,
          boxShadow: [
            BoxShadow(
              color: (color ?? Colors.black).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        // --- 使用 Stack 來疊加遮罩與文字 ---
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24), // 確保遮罩也被裁切圓角
          child: Stack(
            children: [
              // 1. 半透明漸層遮罩 (重要：確保文字清晰)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1), // 頂部較淡
                        Colors.black.withOpacity(0.7), // 底部較深，突顯文字
                      ],
                    ),
                  ),
                ),
              ),
              // 2. 完成狀態的打勾圖示
              if (isCompleted)
                const Positioned(
                  top: 15,
                  right: 15,
                  child: Icon(Icons.check_circle, color: Colors.white, size: 28),
                ),
              // 3. 文字與圖示內容
              Positioned(
                left: 16,
                bottom: 16,
                right: 16, // 確保長文字會折行
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 將圖示移到左下角文字上方
                    Icon(icon, color: Colors.white.withOpacity(0.9), size: 28),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        // 加上一點點陰影，讓文字更立體
                        shadows: [Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 2)],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}