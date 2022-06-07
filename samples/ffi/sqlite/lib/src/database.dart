// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";
import "dart:ffi";

import "package:ffi/ffi.dart";

import "bindings/bindings.dart";

import "bindings/types.dart" as types;
import "bindings/types.dart" hide Database;

import "bindings/constants.dart";
import "collections/closable_iterator.dart";

/// [Database] represents an open connection to a SQLite database.
///
/// All functions against a database may throw [SQLiteError].
///
/// This database interacts with SQLite synchonously.
class Database {
  late DatabaseResource _database;
  bool _open = false;

  /// Open a database located at the file [path].
  Database(String path,
      [int flags = Flags.SQLITE_OPEN_READWRITE | Flags.SQLITE_OPEN_CREATE]) {
    Pointer<Pointer<types.Database>> dbOut = calloc();
    final pathC = Utf8Resource(path.toNativeUtf8());
    final int resultCode =
        bindings.sqlite3_open_v2(pathC.unsafe(), dbOut, flags, nullptr);
    _database = DatabaseResource(dbOut.value);
    calloc.free(dbOut);
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
    final int resultCode = _database.close();
    if (resultCode == Errors.SQLITE_OK) {
      _open = false;
    } else {
      throw _loadError(resultCode);
    }
  }

  /// Execute a query, discarding any returned rows.
  void execute(String query) {
    Pointer<Pointer<Statement>> statementOut = malloc();
    final queryC = Utf8Resource(query.toNativeUtf8());
    int resultCode = _database.prepare(queryC, -1, statementOut, nullptr);
    final statement = StatementResource(statementOut.value);
    calloc.free(statementOut);
    queryC.free();

    while (resultCode == Errors.SQLITE_ROW || resultCode == Errors.SQLITE_OK) {
      resultCode = statement.step();
    }
    statement.finalize();
    if (resultCode != Errors.SQLITE_DONE) {
      throw _loadError(resultCode);
    }
  }

  /// Evaluate a query and return the resulting rows as an iterable.
  Result query(String query) {
    Pointer<Pointer<Statement>> statementOut = malloc();
    final queryC = Utf8Resource(query.toNativeUtf8());
    int resultCode = _database.prepare(queryC, -1, statementOut, nullptr);
    final statement = StatementResource(statementOut.value);
    calloc.free(statementOut);
    queryC.free();

    if (resultCode != Errors.SQLITE_OK) {
      statement.finalize();
      throw _loadError(resultCode);
    }

    Map<String, int> columnIndices = {};
    int columnCount = statement.columnCount;
    for (int i = 0; i < columnCount; i++) {
      String columnName = statement.columnName(i);
      columnIndices[columnName] = i;
    }

    return Result._(this, statement, columnIndices);
  }

  SQLiteException _loadError([int? errorCode]) {
    String errorMessage = _database.errmsg().toDartString();
    if (errorCode == null) {
      return SQLiteException(errorMessage);
    }
    String errorCodeExplanation =
        bindings.sqlite3_errstr(errorCode).toDartString();
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
  final ClosableIterator<Row> _iterator;

  Result._(
    Database database,
    StatementResource statement,
    Map<String, int> columnIndices,
  ) : _iterator = _ResultIterator(statement, columnIndices) {}

  void close() => _iterator.close();

  ClosableIterator<Row> get iterator => _iterator;
}

class _ResultIterator implements ClosableIterator<Row> {
  final StatementResource _statement;
  final Map<String, int> _columnIndices;

  Row? _currentRow;
  bool _closed = false;

  _ResultIterator(this._statement, this._columnIndices) {}

  bool moveNext() {
    if (_closed) {
      throw SQLiteException("The result has already been closed.");
    }
    _currentRow?._setNotCurrent();
    int stepResult = _statement.step();
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
    return _currentRow!;
  }

  void close() {
    _currentRow?._setNotCurrent();
    _closed = true;
    _statement.finalize();
  }
}

class Row {
  final StatementResource _statement;
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
    return readColumnByIndex(_columnIndices[columnName]!, convert: convert);
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
      dynamicType = _typeFromCode(_statement.columnType(columnIndex));
    } else {
      dynamicType =
          _typeFromText(_statement.columnDecltype(columnIndex).toDartString());
    }

    switch (dynamicType) {
      case Type.Integer:
        return readColumnByIndexAsInt(columnIndex);
      case Type.Text:
        return readColumnByIndexAsText(columnIndex);
      case Type.Null:
        return null;
      default:
    }
  }

  /// Reads column [columnName] and converts to [Type.Integer] if not an
  /// integer.
  int readColumnAsInt(String columnName) {
    return readColumnByIndexAsInt(_columnIndices[columnName]!);
  }

  /// Reads column [columnIndex] and converts to [Type.Integer] if not an
  /// integer.
  int readColumnByIndexAsInt(int columnIndex) {
    _checkIsCurrentRow();
    return _statement.columnInt(columnIndex);
  }

  /// Reads column [columnName] and converts to [Type.Text] if not text.
  String readColumnAsText(String columnName) {
    return readColumnByIndexAsText(_columnIndices[columnName]!);
  }

  /// Reads column [columnIndex] and converts to [Type.Text] if not text.
  String readColumnByIndexAsText(int columnIndex) {
    _checkIsCurrentRow();
    return _statement.columnText(columnIndex).toDartString();
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

class DatabaseResource implements Finalizable {
  static final NativeFinalizer _finalizer =
      NativeFinalizer(bindings.sqlite3_close_v2_native_return_void.cast());

  /// [_statement] must never escape [StatementResource], otherwise the
  /// [_finalizer] will run prematurely.
  Pointer<types.Database> _database;

  DatabaseResource(this._database) {
    _finalizer.attach(this, _database.cast(), detach: this);
  }

  int close() {
    _finalizer.detach(this);
    return bindings.sqlite3_close_v2(_database);
  }

  int prepare(Utf8Resource query, int nbytes,
      Pointer<Pointer<Statement>> statementOut, Pointer<Pointer<Utf8>> tail) {
    int result = bindings.sqlite3_prepare_v2(
        _database, query.unsafe(), nbytes, statementOut, tail);
    return result;
  }

  Pointer<Utf8> errmsg() => bindings.sqlite3_errmsg(_database);
}

class StatementResource implements Finalizable {
  static final NativeFinalizer _finalizer =
      NativeFinalizer(bindings.sqlite3_finalize_native_return_void.cast());

  /// [_statement] must never escape [StatementResource], otherwise the
  /// [_finalizer] will run prematurely.
  final Pointer<Statement> _statement;

  StatementResource(this._statement) {
    _finalizer.attach(this, _statement.cast(), detach: this);
  }

  int finalize() {
    _finalizer.detach(this);
    return bindings.sqlite3_finalize(_statement);
  }

  int get columnCount => bindings.sqlite3_column_count(_statement);

  String columnName(int index) =>
      bindings.sqlite3_column_name(_statement, index).toDartString();

  int step() => bindings.sqlite3_step(_statement);

  int columnType(int columnIndex) =>
      bindings.sqlite3_column_type(_statement, columnIndex);

  Pointer<Utf8> columnDecltype(int columnIndex) =>
      bindings.sqlite3_column_decltype(_statement, columnIndex);

  int columnInt(int columnIndex) =>
      bindings.sqlite3_column_int(_statement, columnIndex);

  Pointer<Utf8> columnText(int columnIndex) =>
      bindings.sqlite3_column_text(_statement, columnIndex);
}

class Utf8Resource implements Finalizable {
  static final NativeFinalizer _finalizer = NativeFinalizer(posixFree);

  /// [_cString] must never escape [Utf8Resource], otherwise the
  /// [_finalizer] will run prematurely.
  final Pointer<Utf8> _cString;

  Utf8Resource(this._cString) {
    _finalizer.attach(this, _cString.cast(), detach: this);
  }

  void free() {
    _finalizer.detach(this);
    calloc.free(_cString);
  }

  /// Ensure this [Utf8Resource] stays in scope longer than the inner resource.
  Pointer<Utf8> unsafe() => _cString;
}

final DynamicLibrary stdlib = DynamicLibrary.process();
final posixFree = stdlib.lookup<NativeFunction<Void Function(Pointer)>>("free");

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
  throw Exception("Unknown type [$textRepresentation]");
}

enum Type { Integer, Float, Text, Blob, Null }

enum Convert { DynamicType, StaticType }

class SQLiteException {
  final String message;
  SQLiteException(this.message);

  String toString() => message;
}
