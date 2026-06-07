// lib/services/standards_db.dart
//
// SQLite database that stores all text chunks extracted from
// user-uploaded standard PDFs. Each chunk is tagged with:
//   - standard name + year
//   - page number
//   - detected clause number (if found)
//   - raw text content
//
// Search is keyword-based using SQLite FTS4 (full-text search),
// which is fast enough for the ~5,000–15,000 chunks you'd get
// from a typical standards PDF.

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class StandardChunk {
  final int? id;
  final String standardId;   // e.g. "as_1670_1_2018"
  final String standardName; // e.g. "AS 1670.1-2018"
  final int pageNumber;
  final String clauseRef;    // e.g. "8.4.2" or "" if not detected
  final String content;

  const StandardChunk({
    this.id,
    required this.standardId,
    required this.standardName,
    required this.pageNumber,
    required this.clauseRef,
    required this.content,
  });

  Map<String, dynamic> toMap() => {
    'standard_id':   standardId,
    'standard_name': standardName,
    'page_number':   pageNumber,
    'clause_ref':    clauseRef,
    'content':       content,
  };
}

class StandardMeta {
  final String id;
  final String name;
  final int pageCount;
  final int chunkCount;
  final DateTime uploadedAt;

  const StandardMeta({
    required this.id,
    required this.name,
    required this.pageCount,
    required this.chunkCount,
    required this.uploadedAt,
  });
}

class StandardsDb {
  StandardsDb._();
  static final StandardsDb instance = StandardsDb._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'fire_standards.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Main chunks table
        await db.execute('''
          CREATE TABLE chunks (
            id            INTEGER PRIMARY KEY AUTOINCREMENT,
            standard_id   TEXT NOT NULL,
            standard_name TEXT NOT NULL,
            page_number   INTEGER NOT NULL,
            clause_ref    TEXT NOT NULL,
            content       TEXT NOT NULL
          )
        ''');

        // FTS4 virtual table — FTS5 requires SQLite 3.9.0 (Android 7.0+), FTS4 works on all supported devices
        await db.execute('''
          CREATE VIRTUAL TABLE chunks_fts USING fts4(
            content,
            clause_ref,
            standard_name,
            content="chunks"
          )
        ''');

        // Triggers to keep FTS in sync
        await db.execute('''
          CREATE TRIGGER chunks_ai AFTER INSERT ON chunks BEGIN
            INSERT INTO chunks_fts(rowid, content, clause_ref, standard_name)
            VALUES (new.id, new.content, new.clause_ref, new.standard_name);
          END
        ''');
        await db.execute('''
          CREATE TRIGGER chunks_ad AFTER DELETE ON chunks BEGIN
            INSERT INTO chunks_fts(chunks_fts, rowid, content, clause_ref, standard_name)
            VALUES ('delete', old.id, old.content, old.clause_ref, old.standard_name);
          END
        ''');

        // Standards metadata table
        await db.execute('''
          CREATE TABLE standards_meta (
            id           TEXT PRIMARY KEY,
            name         TEXT NOT NULL,
            page_count   INTEGER NOT NULL,
            chunk_count  INTEGER NOT NULL,
            uploaded_at  TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // ── Insert chunks (called during PDF indexing) ────────────────────────────

  Future<void> insertChunks(List<StandardChunk> chunks) async {
    final database = await db;
    final batch = database.batch();
    for (final chunk in chunks) {
      batch.insert('chunks', chunk.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertMeta(StandardMeta meta) async {
    final database = await db;
    await database.insert(
      'standards_meta',
      {
        'id':          meta.id,
        'name':        meta.name,
        'page_count':  meta.pageCount,
        'chunk_count': meta.chunkCount,
        'uploaded_at': meta.uploadedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── Search ────────────────────────────────────────────────────────────────

  /// Keyword search using FTS5. Returns top [limit] chunks ranked by relevance.
  Future<List<StandardChunk>> search(String query, {int limit = 5}) async {
    final database = await db;

    // Sanitise query for FTS5: wrap each word as a prefix query
    final sanitised = query
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .map((w) => '"${w.replaceAll('"', '')}"')
        .join(' OR ');

    if (sanitised.isEmpty) return [];

    final results = await database.rawQuery('''
      SELECT c.id, c.standard_id, c.standard_name, c.page_number,
             c.clause_ref, c.content
      FROM chunks c
      JOIN chunks_fts ON chunks_fts.rowid = c.id
      WHERE chunks_fts MATCH ?
      LIMIT ?
    ''', [sanitised, limit]);

    return results.map((row) => StandardChunk(
      id:           row['id'] as int,
      standardId:   row['standard_id'] as String,
      standardName: row['standard_name'] as String,
      pageNumber:   row['page_number'] as int,
      clauseRef:    row['clause_ref'] as String,
      content:      row['content'] as String,
    )).toList();
  }

  // ── Library management ────────────────────────────────────────────────────

  Future<List<StandardMeta>> listStandards() async {
    final database = await db;
    final rows = await database.query('standards_meta', orderBy: 'uploaded_at DESC');
    return rows.map((r) => StandardMeta(
      id:          r['id'] as String,
      name:        r['name'] as String,
      pageCount:   r['page_count'] as int,
      chunkCount:  r['chunk_count'] as int,
      uploadedAt:  DateTime.parse(r['uploaded_at'] as String),
    )).toList();
  }

  Future<void> deleteStandard(String standardId) async {
    final database = await db;
    await database.delete('chunks',        where: 'standard_id = ?', whereArgs: [standardId]);
    await database.delete('standards_meta', where: 'id = ?',          whereArgs: [standardId]);
  }

  Future<bool> standardExists(String standardId) async {
    final database = await db;
    final rows = await database.query('standards_meta', where: 'id = ?', whereArgs: [standardId]);
    return rows.isNotEmpty;
  }
}
