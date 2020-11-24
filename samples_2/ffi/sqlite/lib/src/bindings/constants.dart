// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/// Result Codes
///
/// Many SQLite functions return an integer result code from the set shown
/// here in order to indicates success or failure.
///
/// New error codes may be added in future versions of SQLite.
///
/// See also: SQLITE_IOERR_READ | extended result codes,
/// sqlite3_vtab_on_conflict() SQLITE_ROLLBACK | result codes.
class Errors {
  /// Successful result
  static const int SQLITE_OK = 0;

  /// Generic error
  static const int SQLITE_ERROR = 1;

  /// Internal logic error in SQLite
  static const int SQLITE_INTERNAL = 2;

  /// Access permission denied
  static const int SQLITE_PERM = 3;

  /// Callback routine requested an abort
  static const int SQLITE_ABORT = 4;

  /// The database file is locked
  static const int SQLITE_BUSY = 5;

  /// A table in the database is locked
  static const int SQLITE_LOCKED = 6;

  /// A malloc() failed
  static const int SQLITE_NOMEM = 7;

  /// Attempt to write a readonly database
  static const int SQLITE_READONLY = 8;

  /// Operation terminated by sqlite3_interrupt()
  static const int SQLITE_INTERRUPT = 9;

  /// Some kind of disk I/O error occurred
  static const int SQLITE_IOERR = 10;

  /// The database disk image is malformed
  static const int SQLITE_CORRUPT = 11;

  /// Unknown opcode in sqlite3_file_control()
  static const int SQLITE_NOTFOUND = 12;

  /// Insertion failed because database is full
  static const int SQLITE_FULL = 13;

  /// Unable to open the database file
  static const int SQLITE_CANTOPEN = 14;

  /// Database lock protocol error
  static const int SQLITE_PROTOCOL = 15;

  /// Internal use only
  static const int SQLITE_EMPTY = 16;

  /// The database schema changed
  static const int SQLITE_SCHEMA = 17;

  /// String or BLOB exceeds size limit
  static const int SQLITE_TOOBIG = 18;

  /// Abort due to constraint violation
  static const int SQLITE_CONSTRAINT = 19;

  /// Data type mismatch
  static const int SQLITE_MISMATCH = 20;

  /// Library used incorrectly
  static const int SQLITE_MISUSE = 21;

  /// Uses OS features not supported on host
  static const int SQLITE_NOLFS = 22;

  /// Authorization denied
  static const int SQLITE_AUTH = 23;

  /// Not used
  static const int SQLITE_FORMAT = 24;

  /// 2nd parameter to sqlite3_bind out of range
  static const int SQLITE_RANGE = 25;

  /// File opened that is not a database file
  static const int SQLITE_NOTADB = 26;

  /// Notifications from sqlite3_log()
  static const int SQLITE_NOTICE = 27;

  /// Warnings from sqlite3_log()
  static const int SQLITE_WARNING = 28;

  /// sqlite3_step() has another row ready
  static const int SQLITE_ROW = 100;

  /// sqlite3_step() has finished executing
  static const int SQLITE_DONE = 101;
}

/// Flags For File Open Operations
///
/// These bit values are intended for use in the
/// 3rd parameter to the [sqlite3_open_v2()] interface and
/// in the 4th parameter to the [sqlite3_vfs.xOpen] method.
class Flags {
  /// Ok for sqlite3_open_v2()
  static const int SQLITE_OPEN_READONLY = 0x00000001;

  /// Ok for sqlite3_open_v2()
  static const int SQLITE_OPEN_READWRITE = 0x00000002;

  /// Ok for sqlite3_open_v2()
  static const int SQLITE_OPEN_CREATE = 0x00000004;

  /// VFS only
  static const int SQLITE_OPEN_DELETEONCLOSE = 0x00000008;

  /// VFS only
  static const int SQLITE_OPEN_EXCLUSIVE = 0x00000010;

  /// VFS only
  static const int SQLITE_OPEN_AUTOPROXY = 0x00000020;

  /// Ok for sqlite3_open_v2()
  static const int SQLITE_OPEN_URI = 0x00000040;

  /// Ok for sqlite3_open_v2()
  static const int SQLITE_OPEN_MEMORY = 0x00000080;

  /// VFS only
  static const int SQLITE_OPEN_MAIN_DB = 0x00000100;

  /// VFS only
  static const int SQLITE_OPEN_TEMP_DB = 0x00000200;

  /// VFS only
  static const int SQLITE_OPEN_TRANSIENT_DB = 0x00000400;

  /// VFS only
  static const int SQLITE_OPEN_MAIN_JOURNAL = 0x00000800;

  /// VFS only
  static const int SQLITE_OPEN_TEMP_JOURNAL = 0x00001000;

  /// VFS only
  static const int SQLITE_OPEN_SUBJOURNAL = 0x00002000;

  /// VFS only
  static const int SQLITE_OPEN_MASTER_JOURNAL = 0x00004000;

  /// Ok for sqlite3_open_v2()
  static const int SQLITE_OPEN_NOMUTEX = 0x00008000;

  /// Ok for sqlite3_open_v2()
  static const int SQLITE_OPEN_FULLMUTEX = 0x00010000;

  /// Ok for sqlite3_open_v2()
  static const int SQLITE_OPEN_SHAREDCACHE = 0x00020000;

  /// Ok for sqlite3_open_v2()
  static const int SQLITE_OPEN_PRIVATECACHE = 0x00040000;

  /// VFS only
  static const int SQLITE_OPEN_WAL = 0x00080000;
}

class Types {
  static const int SQLITE_INTEGER = 1;
  static const int SQLITE_FLOAT = 2;
  static const int SQLITE_TEXT = 3;
  static const int SQLITE_BLOB = 4;
  static const int SQLITE_NULL = 5;
}
