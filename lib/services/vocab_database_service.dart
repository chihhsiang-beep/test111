import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

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

    final db = await openDatabase(dbPath);
    debugPrint('DB opened.');

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );
    debugPrint('Tables: $tables');

    final columns = await db.rawQuery("PRAGMA table_info(vocab)");
    debugPrint('Columns: $columns');

    return db;
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
}

