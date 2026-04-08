import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import '../models/vocab_item.dart';

class VocabDatabaseService {
  static final VocabDatabaseService instance = VocabDatabaseService._init();
  static Database? _database;

  VocabDatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('toeic_vocab.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = join(dir.path, fileName);

    debugPrint('DB path: $dbPath');

    final exists = await File(dbPath).exists();
    debugPrint('DB exists: $exists');

    if (!exists) {
      debugPrint('Copying DB from assets...');
      final data = await rootBundle.load('assets/db/toeic_vocab.db');
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await File(dbPath).writeAsBytes(bytes, flush: true);
      debugPrint('DB copied.');
    }

    final db = await openDatabase(
      dbPath,
      version: 3,
      onCreate: (db, version) async {
        await _createStudyTables(db);
        await _createChatTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await _createStudyTables(db);
          await _createChatTables(db);
        }
      },
      onOpen: (db) async {
        await _createStudyTables(db);
        await _createChatTables(db);
      },
    );

    debugPrint('DB opened.');

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );
    debugPrint('Tables: $tables');

    final columns = await db.rawQuery("PRAGMA table_info(vocab)");
    debugPrint('Columns: $columns');

    return db;
  }

  Future<void> _createStudyTables(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS study_sessions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      session_type TEXT NOT NULL,
      started_at TEXT NOT NULL,
      finished_at TEXT,
      total_words INTEGER DEFAULT 0,
      known_count INTEGER DEFAULT 0,
      unknown_count INTEGER DEFAULT 0,
      review_rounds INTEGER DEFAULT 0,
      status TEXT DEFAULT 'in_progress',
      unknown_words_json TEXT
    )
  ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS study_session_words (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      session_id INTEGER NOT NULL,
      vocab_id INTEGER NOT NULL,
      stage TEXT NOT NULL,
      result TEXT NOT NULL,
      reviewed_at TEXT NOT NULL,
      FOREIGN KEY (session_id) REFERENCES study_sessions(id)
    )
  ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS favorite_sentences (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      original_text TEXT NOT NULL,
      translated_text TEXT NOT NULL,
      sender_name TEXT,
      is_me INTEGER NOT NULL DEFAULT 0,
      source_mode TEXT,
      topic TEXT,
      created_at TEXT NOT NULL,
      saved_at TEXT NOT NULL
    )
  ''');
  }

  Future<List<VocabItem>> getAllWords({int limit = 100, int offset = 0}) async {
    final db = await database;

    final result = await db.query(
      'vocab',
      orderBy: 'english_word COLLATE NOCASE ASC',
      limit: limit,
      offset: offset,
    );

    debugPrint('getAllWords result count: ${result.length}');
    return result.map((e) => VocabItem.fromMap(e)).toList();
  }

  Future<List<VocabItem>> searchWords(String keyword) async {
    final db = await database;

    debugPrint('Searching keyword: $keyword');

    final result = await db.query(
      'vocab',
      where: '''
        english_word LIKE ? OR
        chinese_definition LIKE ? OR
        category LIKE ? OR
        parts_of_speech LIKE ? OR
        example_en LIKE ? OR
        example_zh LIKE ? OR
        exam_tip LIKE ?
      ''',
      whereArgs: [
        '%$keyword%',
        '%$keyword%',
        '%$keyword%',
        '%$keyword%',
        '%$keyword%',
        '%$keyword%',
        '%$keyword%',
      ],
      orderBy: 'english_word COLLATE NOCASE ASC',
    );

    debugPrint('searchWords result count: ${result.length}');
    return result.map((e) => VocabItem.fromMap(e)).toList();
  }

  Future<void> toggleSaved(int id, bool save) async {
    final db = await database;

    await db.update(
      'vocab',
      {'is_saved': save ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<VocabItem>> getSavedWords() async {
    final db = await database;

    final result = await db.query(
      'vocab',
      where: 'is_saved = ?',
      whereArgs: [1],
      orderBy: 'english_word COLLATE NOCASE ASC',
    );

    debugPrint('getSavedWords result count: ${result.length}');
    return result.map((e) => VocabItem.fromMap(e)).toList();
  }

  Future<List<VocabItem>> getReviewWords({
    int limit = 30,
    bool excludeSaved = false,
  }) async {
    final db = await database;

    final result = await db.query(
      'vocab',
      where: excludeSaved ? 'is_saved = ?' : null,
      whereArgs: excludeSaved ? [0] : null,
      orderBy: 'RANDOM()',
      limit: limit,
    );

    return result.map((e) => VocabItem.fromMap(e)).toList();
  }

  Future<void> markSaved(int id) async {
    final db = await database;
    await db.update(
      'vocab',
      {'is_saved': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getSavedWordCount() async {
    final db = await database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM vocab WHERE is_saved = 1',
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> createStudySession({
    required int totalWords,
    String sessionType = 'toeic',
  }) async {
    final db = await database;

    return await db.insert(
      'study_sessions',
      {
        'session_type': sessionType,
        'started_at': DateTime.now().toIso8601String(),
        'finished_at': null,
        'total_words': totalWords,
        'known_count': 0,
        'unknown_count': 0,
        'review_rounds': 1,
        'status': 'in_progress',
        'unknown_words_json': jsonEncode(<int>[]),
      },
    );
  }

  Future<void> updateStudySessionProgress({
    required int sessionId,
    required int knownCount,
    required int unknownCount,
    required List<int> unknownWordIds,
  }) async {
    final db = await database;

    await db.update(
      'study_sessions',
      {
        'known_count': knownCount,
        'unknown_count': unknownCount,
        'unknown_words_json': jsonEncode(unknownWordIds),
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> finishStudySession({
    required int sessionId,
    required int knownCount,
    required int unknownCount,
    required int reviewRounds,
    required List<int> unknownWordIds,
  }) async {
    final db = await database;

    await db.update(
      'study_sessions',
      {
        'finished_at': DateTime.now().toIso8601String(),
        'known_count': knownCount,
        'unknown_count': unknownCount,
        'review_rounds': reviewRounds,
        'status': 'completed',
        'unknown_words_json': jsonEncode(unknownWordIds),
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> insertStudySessionWord({
    required int sessionId,
    required int vocabId,
    required String stage,
    required String result,
  }) async {
    final db = await database;

    await db.insert(
      'study_session_words',
      {
        'session_id': sessionId,
        'vocab_id': vocabId,
        'stage': stage,
        'result': result,
        'reviewed_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<int> addFavoriteSentence({
    required String originalText,
    required String translatedText,
    required String senderName,
    required bool isMe,
    String? sourceMode,
    String? topic,
    String? createdAt,
  }) async {
    final db = await database;

    return await db.insert(
      'favorite_sentences',
      {
        'original_text': originalText,
        'translated_text': translatedText,
        'sender_name': senderName,
        'is_me': isMe ? 1 : 0,
        'source_mode': sourceMode,
        'topic': topic,
        'created_at': createdAt ?? DateTime.now().toIso8601String(),
        'saved_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<bool> isSentenceFavorited({
    required String originalText,
    required String translatedText,
  }) async {
    final db = await database;

    final result = await db.query(
      'favorite_sentences',
      where: 'original_text = ? AND translated_text = ?',
      whereArgs: [originalText, translatedText],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  Future<void> removeFavoriteSentence({
    required String originalText,
    required String translatedText,
  }) async {
    final db = await database;

    await db.delete(
      'favorite_sentences',
      where: 'original_text = ? AND translated_text = ?',
      whereArgs: [originalText, translatedText],
    );
  }

  Future<bool> toggleFavoriteSentence({
    required String originalText,
    required String translatedText,
    required String senderName,
    required bool isMe,
    String? sourceMode,
    String? topic,
    String? createdAt,
  }) async {
    final alreadySaved = await isSentenceFavorited(
      originalText: originalText,
      translatedText: translatedText,
    );

    if (alreadySaved) {
      await removeFavoriteSentence(
        originalText: originalText,
        translatedText: translatedText,
      );
      return false;
    } else {
      await addFavoriteSentence(
        originalText: originalText,
        translatedText: translatedText,
        senderName: senderName,
        isMe: isMe,
        sourceMode: sourceMode,
        topic: topic,
        createdAt: createdAt,
      );
      return true;
    }
  }

  Future<List<Map<String, dynamic>>> getFavoriteSentences() async {
    final db = await database;

    return await db.query(
      'favorite_sentences',
      orderBy: 'saved_at DESC',
    );
  }
  Future<List<Map<String, dynamic>>> getFavoriteSentencesByContext({
    required String sourceMode,
    String? topic,
  }) async {
    final db = await database;

    if (topic != null && topic.isNotEmpty) {
      return await db.query(
        'favorite_sentences',
        where: 'source_mode = ? AND topic = ?',
        whereArgs: [sourceMode, topic],
        orderBy: 'saved_at DESC',
      );
    }

    return await db.query(
      'favorite_sentences',
      where: 'source_mode = ?',
      whereArgs: [sourceMode],
      orderBy: 'saved_at DESC',
    );
  }

  Future<void> _createChatTables(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS chat_sessions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      session_key TEXT NOT NULL UNIQUE,
      mode TEXT NOT NULL,
      title TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS chat_messages (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      session_id INTEGER NOT NULL,
      role TEXT NOT NULL,
      message TEXT NOT NULL,
      translated_text TEXT,
      extra_json TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY(session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
    )
  ''');
  }

  String _nowIso() => DateTime.now().toIso8601String();

  Future<int> getOrCreateChatSession({
    required String sessionKey,
    required String mode,
    String? title,
  }) async {
    final db = await database;

    final existing = await db.query(
      'chat_sessions',
      where: 'session_key = ?',
      whereArgs: [sessionKey],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final id = existing.first['id'] as int;

      await db.update(
        'chat_sessions',
        {
          'updated_at': _nowIso(),
          if (title != null) 'title': title,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      return id;
    }

    return await db.insert('chat_sessions', {
      'session_key': sessionKey,
      'mode': mode,
      'title': title ?? mode,
      'created_at': _nowIso(),
      'updated_at': _nowIso(),
    });
  }

  Future<List<Map<String, dynamic>>> getChatMessages(int sessionId) async {
    final db = await database;

    return await db.query(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'id ASC',
    );
  }

  Future<int> insertChatMessage({
    required int sessionId,
    required String role,
    required String message,
    String? translatedText,
    Map<String, dynamic>? extraData,
  }) async {
    final db = await database;

    final id = await db.insert('chat_messages', {
      'session_id': sessionId,
      'role': role,
      'message': message,
      'translated_text': translatedText,
      'extra_json': extraData == null ? null : jsonEncode(extraData),
      'created_at': _nowIso(),
    });

    await db.update(
      'chat_sessions',
      {'updated_at': _nowIso()},
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    return id;
  }

  Future<void> clearChatSessionByKey(String sessionKey) async {
    final db = await database;

    final session = await db.query(
      'chat_sessions',
      where: 'session_key = ?',
      whereArgs: [sessionKey],
      limit: 1,
    );

    if (session.isEmpty) return;

    final sessionId = session.first['id'] as int;

    await db.delete(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> deleteChatSessionByKey(String sessionKey) async {
    final db = await database;

    final session = await db.query(
      'chat_sessions',
      where: 'session_key = ?',
      whereArgs: [sessionKey],
      limit: 1,
    );

    if (session.isEmpty) return;

    final sessionId = session.first['id'] as int;

    await db.delete(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );

    await db.delete(
      'chat_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<int> updateChatMessage({
    required int messageId,
    String? message,
    String? translatedText,
    Map<String, dynamic>? extraData,
  }) async {
    final db = await database;

    final data = <String, dynamic>{};

    if (message != null) data['message'] = message;
    if (translatedText != null) data['translated_text'] = translatedText;
    if (extraData != null) data['extra_json'] = jsonEncode(extraData);

    if (data.isEmpty) return 0;

    return await db.update(
      'chat_messages',
      data,
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }
}

