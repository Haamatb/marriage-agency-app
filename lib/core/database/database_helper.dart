// ─────────────────────────────────────────────────────────────────────────────
// database_helper.dart — Cross-platform SQLite initialization & schema
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'marriage_agency.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    String path;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final dir = await getApplicationSupportDirectory();
      await dir.create(recursive: true);
      path = join(dir.path, _dbName);
      return databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: _dbVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          onConfigure: _onConfigure,
          onOpen: _onOpen,
        ),
      );
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, _dbName);
      return openDatabase(
        path,
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
        onOpen: _onOpen,
      );
    }
  }

  Future<void> _onConfigure(Database db) async {
    try {
      await db.execute('PRAGMA foreign_keys = ON');
    } catch (_) {}
    try {
      // In Android SQLite, journal_mode returns a row so rawQuery must be used instead of execute
      await db.rawQuery('PRAGMA journal_mode = WAL');
    } catch (_) {}
    try {
      await db.execute('PRAGMA synchronous = NORMAL');
    } catch (_) {}
  }

  Future<void> _onOpen(Database db) async {
    try {
      await db.execute('ALTER TABLE marriages ADD COLUMN husband_birth_date TEXT;');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE marriages ADD COLUMN wife_birth_date TEXT;');
    } catch (_) {}
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createMarriagesTable(db);
    await _createAgenciesTable(db);
    await _createFTSTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE marriages ADD COLUMN husband_birth_date TEXT;');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE marriages ADD COLUMN wife_birth_date TEXT;');
      } catch (_) {}
    }
  }

  // ── Marriages Table ──────────────────────────────────────────────────────
  Future<void> _createMarriagesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS marriages (
        id                        TEXT PRIMARY KEY,
        record_number             TEXT NOT NULL,
        hijri_date                TEXT,
        gregorian_date            INTEGER,

        -- husband
        husband_name              TEXT,
        husband_id_type           TEXT,
        husband_id_number         TEXT,
        husband_id_issue_place    TEXT,
        husband_id_issue_date     TEXT,
        husband_birth_place       TEXT,
        husband_birth_date        TEXT,
        husband_residence         TEXT,
        husband_nationality       TEXT,
        husband_prev_marital      TEXT,
        husband_education         TEXT,
        husband_profession        TEXT,
        husband_mother_name       TEXT,

        -- wife
        wife_name                 TEXT,
        wife_id_type              TEXT,
        wife_id_number            TEXT,
        wife_id_issue_place       TEXT,
        wife_id_issue_date        TEXT,
        wife_birth_place          TEXT,
        wife_birth_date           TEXT,
        wife_residence            TEXT,
        wife_nationality          TEXT,
        wife_prev_marital         TEXT,
        wife_education            TEXT,
        wife_profession           TEXT,
        wife_mother_name          TEXT,

        -- guardian
        guardian_name             TEXT,
        guardian_relationship     TEXT,
        guardian_id_type          TEXT,
        guardian_id_number        TEXT,
        guardian_id_issue_place   TEXT,
        guardian_id_issue_date    TEXT,

        -- mahr
        mahr_amount               TEXT,
        mahr_details              TEXT,

        -- witnesses (stored as JSON array)
        witnesses_json            TEXT DEFAULT '[]',

        -- status & delivery
        processing_status         TEXT DEFAULT 'missing_files',
        pending_files_json        TEXT DEFAULT '[]',
        husband_delivery_json     TEXT DEFAULT '{}',
        wife_delivery_json        TEXT DEFAULT '{}',

        -- extra & sync
        extra_fields_json         TEXT DEFAULT '{}',
        sync_status               TEXT DEFAULT 'pending_upload',
        synced_at                 INTEGER,
        last_status_update        INTEGER,
        created_at                INTEGER,
        firestore_updated_at      INTEGER
      )
    ''');

    // Indexes for common queries
    await db.execute('CREATE INDEX IF NOT EXISTS idx_marriages_status ON marriages(processing_status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_marriages_sync ON marriages(sync_status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_marriages_record ON marriages(record_number)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_marriages_gregorian ON marriages(gregorian_date)');
  }

  // ── Agencies Table ───────────────────────────────────────────────────────
  Future<void> _createAgenciesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS agencies (
        id                        TEXT PRIMARY KEY,
        agency_number             TEXT NOT NULL,
        agency_type               TEXT,
        title                     TEXT,
        day_name                  TEXT,
        hijri_date                TEXT,
        gregorian_date            INTEGER,

        -- principal
        principal_name            TEXT,
        principal_id_type         TEXT,
        principal_id_number       TEXT,
        principal_id_issue        TEXT,
        principal_phone           TEXT,

        -- agent
        agent_name                TEXT,
        agent_id_type             TEXT,
        agent_id_number           TEXT,
        agent_id_issue            TEXT,
        agent_phone               TEXT,

        -- witnesses (JSON)
        witnesses_json            TEXT DEFAULT '[]',

        -- status & delivery
        status                    TEXT DEFAULT 'draft',
        delivery_info_json        TEXT DEFAULT '{}',

        -- extra & sync
        extra_fields_json         TEXT DEFAULT '{}',
        sync_status               TEXT DEFAULT 'pending_upload',
        synced_at                 INTEGER,
        last_status_update        INTEGER,
        created_at                INTEGER,
        firestore_updated_at      INTEGER
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_agencies_status ON agencies(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_agencies_sync ON agencies(sync_status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_agencies_number ON agencies(agency_number)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_agencies_gregorian ON agencies(gregorian_date)');
  }

  // ── Full-Text Search virtual tables ─────────────────────────────────────
  Future<void> _createFTSTables(Database db) async {
    try {
      await db.execute('''
        CREATE VIRTUAL TABLE IF NOT EXISTS marriages_fts
        USING fts4(
          id UNINDEXED,
          record_number,
          husband_name,
          wife_name,
          guardian_name
        )
      ''');
    } catch (_) {
      // FTS4/5 not enabled on this Android SQLite build; standard indexed queries are used
    }

    try {
      await db.execute('''
        CREATE VIRTUAL TABLE IF NOT EXISTS agencies_fts
        USING fts4(
          id UNINDEXED,
          agency_number,
          title,
          principal_name,
          agent_name
        )
      ''');
    } catch (_) {
      // FTS4/5 not enabled on this Android SQLite build; standard indexed queries are used
    }
  }

  // ── Utility ──────────────────────────────────────────────────────────────
  Future<void> close() async => (await database).close();
}
