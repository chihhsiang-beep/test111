import 'package:flutter/material.dart';
import '../models/vocab_item.dart';
import '../services/vocab_database_service.dart';
import '../utils/vocab_image_mapper.dart';

class VocabReviewPage extends StatefulWidget {
  final List<VocabItem> reviewWords;
  final int knownCount;
  final int totalCount;
  final int? sessionId;

  const VocabReviewPage({
    super.key,
    required this.reviewWords,
    required this.knownCount,
    required this.totalCount,
    required this.sessionId,
  });

  @override
  State<VocabReviewPage> createState() => _VocabReviewPageState();
}

class _VocabReviewPageState extends State<VocabReviewPage> {
  late final List<VocabItem> _initialReviewWords;
  final List<VocabItem> _stillUnknownWords = [];
  final List<VocabItem> _reviewLearnedWords = [];

  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _isFinishing = false;

  VocabItem? get _currentWord {
    if (_initialReviewWords.isEmpty) return null;
    if (_currentIndex < 0 || _currentIndex >= _initialReviewWords.length) {
      return null;
    }
    return _initialReviewWords[_currentIndex];
  }

  int get _reviewCount => _initialReviewWords.length;
  int get _displayProgress => _reviewCount == 0 ? 0 : _currentIndex + 1;

  int get _finalKnownCount => widget.knownCount + _reviewLearnedWords.length;
  int get _finalUnknownCount => _stillUnknownWords.length;

  @override
  void initState() {
    super.initState();
    _initialReviewWords = List<VocabItem>.from(widget.reviewWords);
  }

  Future<void> _markKnownInReview() async {
    final word = _currentWord;
    final sessionId = widget.sessionId;
    if (word == null) return;

    _reviewLearnedWords.add(word);

    try {
      await VocabDatabaseService.instance.markSaved(word.id);

      if (sessionId != null) {
        await VocabDatabaseService.instance.insertStudySessionWord(
          sessionId: sessionId,
          vocabId: word.id,
          stage: 'review_pass',
          result: 'known',
        );

        await VocabDatabaseService.instance.updateStudySessionProgress(
          sessionId: sessionId,
          knownCount: _finalKnownCount,
          unknownCount: _finalUnknownCount,
          unknownWordIds: _stillUnknownWords.map((e) => e.id).toList(),
        );
      }

      debugPrint(
        '_markKnownInReview ok: '
            'sessionId=$sessionId, vocabId=${word.id}, '
            'finalKnown=$_finalKnownCount, finalUnknown=$_finalUnknownCount',
      );
    } catch (e) {
      debugPrint('_markKnownInReview error: $e');
    }

    _goNext();
  }

  Future<void> _markStillUnknown() async {
    final word = _currentWord;
    final sessionId = widget.sessionId;
    if (word == null) return;

    _stillUnknownWords.add(word);

    try {
      if (sessionId != null) {
        await VocabDatabaseService.instance.insertStudySessionWord(
          sessionId: sessionId,
          vocabId: word.id,
          stage: 'review_pass',
          result: 'unknown',
        );

        await VocabDatabaseService.instance.updateStudySessionProgress(
          sessionId: sessionId,
          knownCount: _finalKnownCount,
          unknownCount: _finalUnknownCount,
          unknownWordIds: _stillUnknownWords.map((e) => e.id).toList(),
        );
      }

      debugPrint(
        '_markStillUnknown ok: '
            'sessionId=$sessionId, vocabId=${word.id}, '
            'finalKnown=$_finalKnownCount, finalUnknown=$_finalUnknownCount',
      );
    } catch (e) {
      debugPrint('_markStillUnknown error: $e');
    }

    _goNext();
  }

  void _goNext() {
    if (_currentIndex < _initialReviewWords.length - 1) {
      setState(() {
        _currentIndex++;
        _showAnswer = false;
      });
      return;
    }
    _finishReview();
  }

  Future<void> _finishReview() async {
    if (_isFinishing) return;
    _isFinishing = true;

    final sessionId = widget.sessionId;

    try {
      if (sessionId != null) {
        await VocabDatabaseService.instance.finishStudySession(
          sessionId: sessionId,
          knownCount: _finalKnownCount,
          unknownCount: _finalUnknownCount,
          reviewRounds: 2,
          unknownWordIds: _stillUnknownWords.map((e) => e.id).toList(),
        );

        debugPrint(
          '_finishReview ok: '
              'sessionId=$sessionId, finalKnown=$_finalKnownCount, '
              'finalUnknown=$_finalUnknownCount',
        );
      }
    } catch (e) {
      debugPrint('_finishReview error: $e');
    }

    if (!mounted) return;

    _showResultDialog();
  }

  void _showResultDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('複習完成'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildResultRow('本輪總數', '${widget.totalCount}'),
              const SizedBox(height: 8),
              _buildResultRow('第一輪已記住', '${widget.knownCount}'),
              const SizedBox(height: 8),
              _buildResultRow('第二輪新記住', '${_reviewLearnedWords.length}'),
              const SizedBox(height: 8),
              _buildResultRow('最後仍不熟', '${_stillUnknownWords.length}'),
              const Divider(height: 24),
              _buildResultRow('最終記住總數', '$_finalKnownCount'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('返回'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final total = _reviewCount == 0 ? 1 : _reviewCount;
    final progress = _displayProgress.clamp(0, total) / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '再複習一次',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '先自己想，點卡片再看答案',
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
            _StatChip(label: '進度', value: '$_displayProgress / $_reviewCount'),
            const SizedBox(width: 8),
            _StatChip(label: '已想起', value: '${_reviewLearnedWords.length}'),
            const SizedBox(width: 8),
            _StatChip(label: '仍不熟', value: '${_stillUnknownWords.length}'),
          ],
        ),
      ],
    );
  }

  Widget _buildCard() {
    final word = _currentWord;
    if (word == null) {
      return const Center(
        child: Text(
          '沒有需要複習的單字',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

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
          color: Colors.black.withOpacity(0.10),
        ),
        alignment: Alignment.bottomLeft,
        padding: const EdgeInsets.all(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _showAnswer ? '已顯示答案' : '點擊卡片顯示答案',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(VocabItem word) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _showAnswer
              ? Column(
            key: const ValueKey('answer'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
            ],
          )
              : Container(
            key: const ValueKey('hidden'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 28,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              '先在腦中回想中文意思，再點一下卡片顯示答案。',
              style: TextStyle(
                fontSize: 17,
                color: Color(0xFF6B7280),
                height: 1.6,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    final disabled = _isFinishing || _currentWord == null;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: disabled ? null : _markStillUnknown,
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
            onPressed: disabled ? null : _markKnownInReview,
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
    if (_initialReviewWords.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pop();
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F4F6),
        elevation: 0,
        title: const Text(
          '不熟單字複習',
          style: TextStyle(color: Color(0xFF111827)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: _initialReviewWords.isEmpty
              ? const Center(child: Text('沒有需要複習的單字'))
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