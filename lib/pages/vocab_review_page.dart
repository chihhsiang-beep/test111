import 'package:flutter/material.dart';
import '../models/vocab_item.dart';
import '../utils/vocab_image_mapper.dart';

class VocabReviewPage extends StatefulWidget {
  final List<VocabItem> reviewWords;
  final int knownCount;
  final int totalCount;

  const VocabReviewPage({
    super.key,
    required this.reviewWords,
    required this.knownCount,
    required this.totalCount,
  });

  @override
  State<VocabReviewPage> createState() => _VocabReviewPageState();
}

class _VocabReviewPageState extends State<VocabReviewPage> {
  late List<VocabItem> _words;
  final List<VocabItem> _againWords = [];

  bool _showAnswer = false;
  int _currentIndex = 0;
  int _round = 1;
  bool _finished = false;

  VocabItem? get _currentWord {
    if (_words.isEmpty) return null;
    if (_currentIndex < 0 || _currentIndex >= _words.length) return null;
    return _words[_currentIndex];
  }

  @override
  void initState() {
    super.initState();
    _words = List<VocabItem>.from(widget.reviewWords);
    if (_words.isEmpty) {
      _finished = true;
    }
  }

  void _knowIt() {
    _nextWord();
  }

  void _reviewAgain() {
    final word = _currentWord;
    if (word != null) {
      _againWords.add(word);
    }
    _nextWord();
  }

  void _nextWord() {
    if (_currentIndex < _words.length - 1) {
      setState(() {
        _currentIndex++;
        _showAnswer = false;
      });
      return;
    }

    if (_againWords.isEmpty) {
      setState(() {
        _finished = true;
      });
      return;
    }

    setState(() {
      _words = List<VocabItem>.from(_againWords);
      _againWords.clear();
      _currentIndex = 0;
      _showAnswer = false;
      _round++;
    });
  }

  Widget _buildHeader() {
    final total = _words.isEmpty ? 1 : _words.length;
    final progress = ((_currentIndex + 1).clamp(0, total)) / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '複習不熟單字',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Round $_round · 點一下卡片顯示中文',
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.black12,
            valueColor: const AlwaysStoppedAnimation(Color(0xFFE07A5F)),
          ),
        ),
      ],
    );
  }

  Widget _buildCard() {
    final word = _currentWord;
    if (word == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        setState(() {
          _showAnswer = !_showAnswer;
        });
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Column(
            children: [
              _buildCardImageArea(word),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: _buildCardContent(word),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardImageArea(VocabItem word) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        image: DecorationImage(
          image: AssetImage(VocabImageMapper.getCategoryImage(word)),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          color: Colors.black.withOpacity(0.08),
        ),
      ),
    );
  }

  Widget _buildCardContent(VocabItem word) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          word.word,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        if (word.partOfSpeech.isNotEmpty)
          Text(
            '詞性：${word.partOfSpeech}',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
        const SizedBox(height: 20),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 180),
          crossFadeState: _showAnswer
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              children: [
                Icon(Icons.touch_app, size: 38, color: Color(0xFF4E6CB3)),
                SizedBox(height: 10),
                Text(
                  '點一下顯示中文',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
          secondChild: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  word.definitionZh,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                if (word.category.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    '分類：${word.category}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
                if (word.exampleEn.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    word.exampleEn,
                    style: const TextStyle(
                      fontSize: 17,
                      color: Color(0xFF374151),
                      height: 1.5,
                    ),
                  ),
                ],
                if (word.exampleZh.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    word.exampleZh,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),
                ],
                if (word.examTip.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    '考點：${word.examTip}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildFinishedView() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events,
              size: 64,
              color: Color(0xFFE07A5F),
            ),
            const SizedBox(height: 16),
            const Text(
              '複習完成',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '第一輪記住：${widget.knownCount} / ${widget.totalCount}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              '第二階段已完成',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _showAnswer ? _reviewAgain : null,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              side: const BorderSide(color: Colors.black26),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              backgroundColor: Colors.white,
            ),
            child: const Text(
              '再看一次',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: ElevatedButton(
            onPressed: _showAnswer ? _knowIt : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text(
              '我知道了',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F4F6),
        elevation: 0,
        title: const Text(
          '複習不熟單字',
          style: TextStyle(color: Color(0xFF111827)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: _finished
              ? _buildFinishedView()
              : Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 14),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: _buildCard(),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }
}