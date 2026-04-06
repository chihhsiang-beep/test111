import 'package:flutter/material.dart';
import 'package:test111/pages/vocabulary_menu_page.dart';
import 'chat_page.dart';
import 'toeic_vocab_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: GridView.count(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 0.85,
        children: [
          _ImageCard(
            title: 'AI 聊天室',
            subtitle: '',
            imagePath: 'assets/Starlit Conversations.png',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatPage()),
            ),
          ),

          _ImageCard(
            title: '單字複習',
            subtitle: '',
            imagePath: 'assets/Constellation of Words.png',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const VocabularyMenuPage()),
            ),
          ),

          const _ImageCard(
            title: '文章閱讀',
            subtitle: '',
            imagePath: 'assets/Midnight Stacks.png',
          ),

          const _ImageCard(
            title: '聽力挑戰',
            subtitle: '',
            imagePath: 'assets/Echoform.png',
          ),
        ],
      ),
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
            IconButton(
              icon: const Icon(
                Icons.home,
                color: Color(0xFFE07A5F),
                size: 28,
              ),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(
                Icons.search,
                color: Colors.black45,
                size: 28,
              ),
              onPressed: () {},
            ),
            const SizedBox(width: 50),
            IconButton(
              icon: const Icon(
                Icons.person_outline,
                color: Colors.black45,
                size: 28,
              ),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(
                Icons.logout,
                color: Colors.black45,
                size: 28,
              ),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imagePath;
  final Color? color;
  final bool isCompleted;
  final VoidCallback? onTap;

  const _ImageCard({
    required this.title,
    required this.subtitle,
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
          color: color ?? Colors.grey.shade300,
          image: imagePath != null
              ? DecorationImage(
            image: AssetImage(imagePath!),
            fit: BoxFit.cover,
            colorFilter: isCompleted
                ? const ColorFilter.mode(
              Colors.grey,
              BlendMode.saturation,
            )
                : null,
          )
              : null,
          boxShadow: [
            BoxShadow(
              color: (color ?? Colors.black).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.05),
                        Colors.black.withOpacity(0.18),
                        Colors.black.withOpacity(0.65),
                      ],
                    ),
                  ),
                ),
              ),

              if (isCompleted)
                const Positioned(
                  top: 15,
                  right: 15,
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 28,
                  ),
                ),

              Positioned(
                left: 16,
                right: 16,
                bottom: 18,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black38,
                            offset: Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
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