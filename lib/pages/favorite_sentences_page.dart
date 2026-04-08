import 'package:flutter/material.dart';
import '../services/vocab_database_service.dart';

class FavoriteSentencesPage extends StatefulWidget {
  final String sourceMode;
  final String? topic;

  const FavoriteSentencesPage({
    super.key,
    required this.sourceMode,
    this.topic,
  });

  @override
  State<FavoriteSentencesPage> createState() => _FavoriteSentencesPageState();
}

class _FavoriteSentencesPageState extends State<FavoriteSentencesPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rows =
      await VocabDatabaseService.instance.getFavoriteSentencesByContext(
        sourceMode: widget.sourceMode,
        topic: widget.topic,
      );

      if (!mounted) return;
      setState(() {
        _items = rows;
      });
    } catch (e) {
      debugPrint('_loadItems error: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteItem(Map<String, dynamic> row) async {
    final originalText = (row['original_text'] ?? '').toString();
    final translatedText = (row['translated_text'] ?? '').toString();

    try {
      await VocabDatabaseService.instance.removeFavoriteSentence(
        originalText: originalText,
        translatedText: translatedText,
      );

      if (!mounted) return;

      setState(() {
        _items.remove(row);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已刪除收藏句子'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      debugPrint('_deleteItem error: $e');
    }
  }

  String _pageTitle() {
    switch (widget.sourceMode) {
      case 'free_chat':
        return '隨意聊天收藏';
      case 'review_chat':
        return '複習聊天收藏';
      case 'topic_chat':
        return widget.topic == null ? '主題聊天收藏' : '${widget.topic}收藏';
      case 'model_select':
        return '聊天收藏';
      default:
        return '收藏句子';
    }
  }

  String _formatSavedAt(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  Widget _buildCard(Map<String, dynamic> row) {
    final originalText = (row['original_text'] ?? '').toString();
    final translatedText = (row['translated_text'] ?? '').toString();
    final savedAt = _formatSavedAt((row['saved_at'] ?? '').toString());
    final senderName = (row['sender_name'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          if (senderName.isNotEmpty)
            Text(
              senderName,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          if (senderName.isNotEmpty) const SizedBox(height: 6),
          Text(
            originalText,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              translatedText,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  savedAt.isEmpty ? '' : '已收藏於 $savedAt',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _deleteItem(row),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('刪除'),
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
        title: Text(
          _pageTitle(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
              ? const Center(
            child: Text(
              '目前沒有收藏句子',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          )
              : RefreshIndicator(
            onRefresh: _loadItems,
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return _buildCard(_items[index]);
              },
            ),
          ),
        ),
      ),
    );
  }
}