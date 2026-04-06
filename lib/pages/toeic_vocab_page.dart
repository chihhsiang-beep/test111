import 'package:flutter/material.dart';
import '../models/vocab_item.dart';
import '../services/vocab_database_service.dart';
import '../utils/vocab_image_mapper.dart';
import 'vocab_review_page.dart';

class ToeicVocabPage extends StatefulWidget {
  const ToeicVocabPage({super.key});

  @override
  State<ToeicVocabPage> createState() => _ToeicVocabPageState();
}

class _ToeicVocabPageState extends State<ToeicVocabPage> {
  final List<VocabItem> _sessionWords = [];
  final List<VocabItem> _unknownWords = [];
  final List<VocabItem> _knownWords = [];

  bool _isLoading = true;
  String? _errorMessage;
  int _currentIndex = 0;

  VocabItem? get _currentWord {
    if (_sessionWords.isEmpty) return null;
    if (_currentIndex < 0 || _currentIndex >= _sessionWords.length) return null;
    return _sessionWords[_currentIndex];
  }

  int get _totalCount => _sessionWords.length;
  int get _displayProgress => _sessionWords.isEmpty ? 0 : _currentIndex + 1;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentIndex = 0;
      _sessionWords.clear();
      _unknownWords.clear();
      _knownWords.clear();
    });

    try {
      final words = await VocabDatabaseService.instance.getReviewWords(
        limit: 30,
        excludeSaved: false,
      );

      if (!mounted) return;

      setState(() {
        _sessionWords.addAll(words);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleKnown() async {
    final word = _currentWord;
    if (word == null) return;

    _knownWords.add(word);

    try {
      await VocabDatabaseService.instance.markSaved(word.id);
    } catch (_) {}

    _goNext();
  }

  void _handleUnknown() {
    final word = _currentWord;
    if (word == null) return;

    _unknownWords.add(word);
    _goNext();
  }

  void _goNext() {
    if (_currentIndex < _sessionWords.length - 1) {
      setState(() {
        _currentIndex++;
      });
      return;
    }

    _finishRound();
  }

  void _finishRound() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => VocabReviewPage(
          reviewWords: List<VocabItem>.from(_unknownWords),
          knownCount: _knownWords.length,
          totalCount: _sessionWords.length,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final total = _totalCount == 0 ? 1 : _totalCount;
    final progress = _displayProgress.clamp(0, total) / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TOEIC 單字庫',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '右滑代表記住，左滑代表還不熟',
          style: TextStyle(
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
        const SizedBox(height: 10),
        Row(
          children: [
            _StatChip(label: '進度', value: '$_displayProgress / $_totalCount'),
            const SizedBox(width: 8),
            _StatChip(label: '記住', value: '${_knownWords.length}'),
            const SizedBox(width: 8),
            _StatChip(label: '不熟', value: '${_unknownWords.length}'),
          ],
        ),
      ],
    );
  }

  Widget _buildMainCard() {
    final word = _currentWord;
    if (word == null) return const SizedBox.shrink();

    return Dismissible(
      key: ValueKey('${word.id}-${_currentIndex}'),
      direction: DismissDirection.horizontal,
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          _handleKnown();
        } else {
          _handleUnknown();
        }
      },
      background: const _SwipeHintCard(
        color: Colors.green,
        icon: Icons.favorite,
        text: '記住了',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: const _SwipeHintCard(
        color: Colors.orange,
        icon: Icons.refresh,
        text: '還不熟',
        alignment: Alignment.centerRight,
      ),
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
            fontSize: 30,
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
        const SizedBox(height: 10),
        Text(
          word.definitionZh,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
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
        if (word.toeicScoreRange.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            '分數區間：${word.toeicScoreRange}',
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
        if (word.exampleEn.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            word.exampleEn,
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF111827),
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
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _handleUnknown,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              side: const BorderSide(color: Colors.black26),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              backgroundColor: Colors.white,
            ),
            child: const Text(
              '還不熟',
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
            onPressed: _handleKnown,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text(
              '我記住了',
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
          'TOEIC 單字庫',
          style: TextStyle(color: Color(0xFF111827)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Text('發生錯誤：$_errorMessage'))
              : _sessionWords.isEmpty
              ? const Center(child: Text('沒有可用的單字'))
              : Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 14),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 520,
                    ),
                    child: _buildMainCard(),
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

class _SwipeHintCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  final Alignment alignment;

  const _SwipeHintCard({
    required this.color,
    required this.icon,
    required this.text,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment == Alignment.centerLeft;

    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment:
        isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!isLeft)
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(width: 10),
          Icon(icon, color: color, size: 34),
          if (isLeft) ...[
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}