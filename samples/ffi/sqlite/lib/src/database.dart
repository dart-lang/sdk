// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";
import "dart:ffi";

import "bindings/bindings.dart";
import "bindings/types.dart";
import "bindings/constants.dart";
import "collections/closable_iterator.dart";
import "ffi/cstring.dart";

/// [Database] represents an open connection to a SQLite database.
///
/// All functions against a database may throw [SQLiteError].
///
/// This database interacts with SQLite synchonously.
class Database {
  DatabasePointer _database;
  bool _open = false;

  /// Open a database located at the file [path].
  Database(String path,
      [int flags = Flags.SQLITE_OPEN_READWRITE | Flags.SQLITE_OPEN_CREATE]) {
    Pointer<DatabasePointer> dbOut = allocate();
    CString pathC = CString.allocate(path);
    final int resultCode =
        bindings.sqlite3_open_v2(pathC, dbOut, flags, fromAddress(0));
    _database = dbOut.load();
    dbOut.free();
    pathC.free();

    if (resultCode == Errors.SQLITE_OK) {
      _open = true;
    } else {
      // Even if "open" fails, sqlite3 will still create a database object. We
      // can just destroy it.
      SQLiteException exception = _loadError(resultCode);
      close();
      throw exception;
    }
  }

  /// Close the database.
  ///
  /// This should only be called once on a database unless an exception is
  /// thrown. It should be called at least once to finalize the database and
  /// avoid resource leaks.
  void close() {
    assert(_open);
    final int resultCode = bindings.sqlite3_close_v2(_database);
    if (resultCode == Errors.SQLITE_OK) {
      _open = false;
    } else {
      throw _loadError(resultCode);
    }
  }

  /// Execute a query, discarding any returned rows.
  void execute(String query) {
    Pointer<StatementPointer> statementOut = allocate();
    CString queryC = CString.allocate(query);
    int resultCode = bindings.sqlite3_prepare_v2(
        _database, queryC, -1, statementOut, fromAddress(0));
    StatementPointer statement = statementOut.load();
    statementOut.free();
    queryC.free();

    while (resultCode == Errors.SQLITE_ROW || resultCode == Errors.SQLITE_OK) {
      resultCode = bindings.sqlite3_step(statement);
    }
    bindings.sqlite3_finalize(statement);
    if (resultCode != Errors.SQLITE_DONE) {
      throw _loadError(resultCode);
    }
  }

  /// Evaluate a query and return the resulting rows as an iterable.
  Result query(String query) {
    Pointer<StatementPointer> statementOut = allocate();
    CString queryC = CString.allocate(query);
    int resultCode = bindings.sqlite3_prepare_v2(
        _database, queryC, -1, statementOut, fromAddress(0));
    StatementPointer statement = statementOut.load();
    statementOut.free();
    queryC.free();

    if (resultCode != Errors.SQLITE_OK) {
      bindings.sqlite3_finalize(statement);
      throw _loadError(resultCode);
    }

    Map<String, int> columnIndices = {};
    int columnCount = bindings.sqlite3_column_count(statement);
    for (int i = 0; i < columnCount; i++) {
      String columnName =
          CString.fromUtf8(bindings.sqlite3_column_name(statement, i));
      columnIndices[columnName] = i;
    }

    return Result._(this, statement, columnIndices);
  }

  SQLiteException _loadError([int errorCode]) {
    String errorMessage = CString.fromUtf8(bindings.sqlite3_errmsg(_database));
    if (errorCode == null) {
      return SQLiteException(errorMessage);
    }
    String errorCodeExplanation =
        CString.fromUtf8(bindings.sqlite3_errstr(errorCode));
    return SQLiteException(
        "$errorMessage (Code $errorCode: $errorCodeExplanation)");
  }
}

/// [Result] represents a [Database.query]'s result and provides an [Iterable]
/// interface for the results to be consumed.
///
/// Please note that this iterator should be [close]d manually if not all [Row]s
/// are consumed.
class Result extends IterableBase<Row> implements ClosableIterable<Row> {
  final Database _database;
  final ClosableIterator<Row> _iterator;
  final StatementPointer _statement;
  final Map<String, int> _columnIndices;

  Row _currentRow = null;

  Result._(
    this._database,
    this._statement,
    this._columnIndices,
  ) : _iterator = _ResultIterator(_statement, _columnIndices) {}

  void close() => _iterator.close();

  ClosableIterator<Row> get iterator => _iterator;
}

class _ResultIterator implements ClosableIterator<Row> {
  final StatementPointer _statement;
  final Map<String, int> _columnIndices;

  Row _currentRow = null;
  bool _closed = false;

  _ResultIterator(this._statement, this._columnIndices) {}

  bool moveNext() {
    if (_closed) {
      throw SQLiteException("The result has already been closed.");
    }
    _currentRow?._setNotCurrent();
    int stepResult = bindings.sqlite3_step(_statement);
    if (stepResult == Errors.SQLITE_ROW) {
      _currentRow = Row._(_statement, _columnIndices);
      return true;
    } else {
      close();
      return false;
    }
  }

  Row get current {
    if (_closed) {
      throw SQLiteException("The result has already been closed.");
    }
    return _currentRow;
  }

  void close() {
    _currentRow?._setNotCurrent();
    _closed = true;
    bindings.sqlite3_finalize(_statement);
  }
}

class Row {
  final StatementPointer _statement;
  final Map<String, int> _columnIndices;

  bool _isCurrentRow = true;

  Row._(this._statement, this._columnIndices) {}

  /// Reads column [columnName].
  ///
  /// By default it returns a dynamically typed value. If [convert] is set to
  /// [Convert.StaticType] the value is converted to the static type computed
  /// for the column by the query compiler.
  dynamic readColumn(String columnName,
      {Convert convert = Convert.DynamicType}) {
    return readColumnByIndex(_columnIndices[columnName], convert: convert);
  }

  /// Reads column [columnName].
  ///
  /// By default it returns a dynamically typed value. If [convert] is set to
  /// [Convert.StaticType] the value is converted to the static type computed
  /// for the column by the query compiler.
  dynamic readColumnByIndex(int columnIndex,
      {Convert convert = Convert.DynamicType}) {
    _checkIsCurrentRow();

    Type dynamicType;
    if (convert == Convert.DynamicType) {
      dynamicType =
          _typeFromCode(bindings.sqlite3_column_type(_statement, columnIndex));
    } else {
      dynamicType = _typeFromText(CString.fromUtf8(
          bindings.sqlite3_column_decltype(_statement, columnIndex)));
    }

    switch (dynamicType) {
      case Type.Integer:
        return readColumnByIndexAsInt(columnIndex);
      case Type.Text:
        return readColumnByIndexAsText(columnIndex);
      case Type.Null:
        return null;
        break;
      default:
    }
  }

  /// Reads column [columnName] and converts to [Type.Integer] if not an
  /// integer.
  int readColumnAsInt(String columnName) {
    return readColumnByIndexAsInt(_columnIndices[columnName]);
  }

  /// Reads column [columnIndex] and converts to [Type.Integer] if not an
  /// integer.
  int readColumnByIndexAsInt(int columnIndex) {
    _checkIsCurrentRow();
    return bindings.sqlite3_column_int(_statement, columnIndex);
  }

  /// Reads column [columnName] and converts to [Type.Text] if not text.
  String readColumnAsText(String columnName) {
    return readColumnByIndexAsText(_columnIndices[columnName]);
  }

  /// Reads column [columnIndex] and converts to [Type.Text] if not text.
  String readColumnByIndexAsText(int columnIndex) {
    _checkIsCurrentRow();
    return CString.fromUtf8(
        bindings.sqlite3_column_text(_statement, columnIndex));
  }

  void _checkIsCurrentRow() {
    if (!_isCurrentRow) {
      throw Exception(
          "This row is not the current row, reading data from the non-current"
          " row is not supported by sqlite.");
    }
  }

  void _setNotCurrent() {
    _isCurrentRow = false;
  }
}

Type _typeFromCode(int code) {
  switch (code) {
    case Types.SQLITE_INTEGER:
      return Type.Integer;
    case Types.SQLITE_FLOAT:
      return Type.Float;
    case Types.SQLITE_TEXT:
      return Type.Text;
    case Types.SQLITE_BLOB:
      return Type.Blob;
    case Types.SQLITE_NULL:
      return Type.Null;
  }
  throw Exception("Unknown type [$code]");
}

Type _typeFromText(String textRepresentation) {
  switch (textRepresentation) {
    case "integer":
      return Type.Integer;
    case "float":
      return Type.Float;
    case "text":
      return Type.Text;
    case "blob":
      return Type.Blob;
    case "null":
      return Type.Null;
  }
  if (textRepresentation == null) return Type.Null;
  throw Exception("Unknown type [$textRepresentation]");
}

enum Type { Integer, Float, Text, Blob, Null }

enum Convert { DynamicType, StaticType }

class SQLiteException {
  final String message;
  SQLiteException(this.message);

  String toString() => message;
}
