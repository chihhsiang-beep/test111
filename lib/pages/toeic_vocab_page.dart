import 'package:flutter/material.dart';
import '../models/vocab_item.dart';
import '../services/vocab_database_service.dart';

class VocabPage extends StatefulWidget {
  const VocabPage({super.key});

  @override
  State<VocabPage> createState() => _VocabPageState();
}

class _VocabPageState extends State<VocabPage> {
  final TextEditingController _searchController = TextEditingController();

  List<VocabItem> _words = [];
  bool _isLoading = true;
  bool _showSavedOnly = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final words = _showSavedOnly
          ? await VocabDatabaseService.instance.getSavedWords()
          : await VocabDatabaseService.instance.getAllWords(limit: 200);

      if (!mounted) return;

      setState(() {
        _words = words;
      });
    } catch (e, st) {
      debugPrint('LOAD ERROR: $e');
      debugPrint('$st');

      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _words = [];
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchWords(String keyword) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (keyword.trim().isEmpty) {
        await _loadWords();
        return;
      }

      final words = await VocabDatabaseService.instance.searchWords(keyword);

      if (!mounted) return;

      setState(() {
        _words = _showSavedOnly
            ? words.where((e) => e.isSaved == 1).toList()
            : words;
      });
    } catch (e, st) {
      debugPrint('SEARCH ERROR: $e');
      debugPrint('$st');

      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _words = [];
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSaved(VocabItem item) async {
    try {
      await VocabDatabaseService.instance.toggleSaved(
        item.id,
        item.isSaved == 0,
      );

      if (_searchController.text.trim().isEmpty) {
        await _loadWords();
      } else {
        await _searchWords(_searchController.text);
      }
    } catch (e, st) {
      debugPrint('TOGGLE ERROR: $e');
      debugPrint('$st');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('收藏更新失敗：$e')),
      );
    }
  }

  Widget _buildWordCard(VocabItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(
          item.word,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.definitionZh),

              if (item.partOfSpeech.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('詞性：${item.partOfSpeech}'),
              ],

              if (item.category.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('分類：${item.category}'),
              ],

              if (item.toeicScoreRange.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('分數區間：${item.toeicScoreRange}'),
              ],

              if (item.exampleEn.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('例句：${item.exampleEn}'),
              ],

              if (item.exampleZh.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('中文：${item.exampleZh}'),
              ],

              if (item.examTip.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('考點：${item.examTip}'),
              ],
            ],
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            item.isSaved == 1 ? Icons.favorite : Icons.favorite_border,
            color: item.isSaved == 1 ? Colors.red : null,
          ),
          onPressed: () => _toggleSaved(item),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '發生錯誤：\n$_errorMessage',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (_words.isEmpty) {
      return const Center(child: Text('沒有找到資料'));
    }

    return ListView.builder(
      itemCount: _words.length,
      itemBuilder: (context, index) => _buildWordCard(_words[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TOEIC 單字庫'),
        actions: [
          IconButton(
            icon: Icon(
              _showSavedOnly ? Icons.bookmark : Icons.bookmark_border,
            ),
            onPressed: () async {
              setState(() {
                _showSavedOnly = !_showSavedOnly;
              });

              if (_searchController.text.trim().isEmpty) {
                await _loadWords();
              } else {
                await _searchWords(_searchController.text);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: _searchWords,
              decoration: InputDecoration(
                hintText: '搜尋英文 / 中文 / 分類',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}