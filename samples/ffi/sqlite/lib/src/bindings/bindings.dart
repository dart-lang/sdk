// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "dart:ffi";
import "package:ffi/ffi.dart";

import "../ffi/dylib_utils.dart";

import "signatures.dart";
import "types.dart";

class _SQLiteBindings {
  DynamicLibrary sqlite;

  /// Opening A New Database Connection
  ///
  /// ^These routines open an SQLite database file as specified by the
  /// filename argument. ^The filename argument is interpreted as UTF-8 for
  /// sqlite3_open() and sqlite3_open_v2() and as UTF-16 in the native byte
  /// order for sqlite3_open16(). ^(A database connection handle is usually
  /// returned in *ppDb, even if an error occurs.  The only exception is that
  /// if SQLite is unable to allocate memory to hold the sqlite3 object,
  /// a NULL will be written into *ppDb instead of a pointer to the sqlite3
  /// object.)^ ^(If the database is opened (and/or created) successfully, then
  /// [SQLITE_OK] is returned.  Otherwise an error code is returned.)^ ^The
  /// [sqlite3_errmsg] or sqlite3_errmsg16() routines can be used to obtain
  /// an English language description of the error following a failure of any
  /// of the sqlite3_open() routines.
  int Function(Pointer<Utf8> filename, Pointer<Pointer<Database>> databaseOut,
      int flags, Pointer<Utf8> vfs) sqlite3_open_v2;

  int Function(Pointer<Database> database) sqlite3_close_v2;

  /// Compiling An SQL Statement
  ///
  /// To execute an SQL query, it must first be compiled into a byte-code
  /// program using one of these routines.
  ///
  /// The first argument, "db", is a database connection obtained from a
  /// prior successful call to sqlite3_open, [sqlite3_open_v2] or
  /// sqlite3_open16.  The database connection must not have been closed.
  ///
  /// The second argument, "zSql", is the statement to be compiled, encoded
  /// as either UTF-8 or UTF-16.  The sqlite3_prepare() and sqlite3_prepare_v2()
  /// interfaces use UTF-8, and sqlite3_prepare16() and sqlite3_prepare16_v2()
  /// use UTF-16.
  ///
  /// ^If the nByte argument is less than zero, then zSql is read up to the
  /// first zero terminator. ^If nByte is non-negative, then it is the maximum
  /// number of  bytes read from zSql.  ^When nByte is non-negative, the
  /// zSql string ends at either the first '\000' or '\u0000' character or
  /// the nByte-th byte, whichever comes first. If the caller knows
  /// that the supplied string is nul-terminated, then there is a small
  /// performance advantage to be gained by passing an nByte parameter that
  /// is equal to the number of bytes in the input string <i>including</i>
  /// the nul-terminator bytes.
  ///
  /// ^If pzTail is not NULL then *pzTail is made to point to the first byte
  /// past the end of the first SQL statement in zSql.  These routines only
  /// compile the first statement in zSql, so *pzTail is left pointing to
  /// what remains uncompiled.
  ///
  /// ^*ppStmt is left pointing to a compiled prepared statement that can be
  /// executed using sqlite3_step.  ^If there is an error, *ppStmt is set
  /// to NULL.  ^If the input text contains no SQL (if the input is an empty
  /// string or a comment) then *ppStmt is set to NULL.
  /// The calling procedure is responsible for deleting the compiled
  /// SQL statement using [sqlite3_finalize] after it has finished with it.
  /// ppStmt may not be NULL.
  ///
  /// ^On success, the sqlite3_prepare family of routines return [SQLITE_OK];
  /// otherwise an error code is returned.
  ///
  /// The sqlite3_prepare_v2() and sqlite3_prepare16_v2() interfaces are
  /// recommended for all new programs. The two older interfaces are retained
  /// for backwards compatibility, but their use is discouraged.
  /// ^In the "v2" interfaces, the prepared statement
  /// that is returned (the sqlite3_stmt object) contains a copy of the
  /// original SQL text. This causes the [sqlite3_step] interface to
  /// behave differently in three ways:
  int Function(
      Pointer<Database> database,
      Pointer<Utf8> query,
      int nbytes,
      Pointer<Pointer<Statement>> statementOut,
      Pointer<Pointer<Utf8>> tail) sqlite3_prepare_v2;

  /// Evaluate An SQL Statement
  ///
  /// After a prepared statement has been prepared using either
  /// [sqlite3_prepare_v2] or sqlite3_prepare16_v2() or one of the legacy
  /// interfaces sqlite3_prepare() or sqlite3_prepare16(), this function
  /// must be called one or more times to evaluate the statement.
  ///
  /// The details of the behavior of the sqlite3_step() interface depend
  /// on whether the statement was prepared using the newer "v2" interface
  /// [sqlite3_prepare_v2] and sqlite3_prepare16_v2() or the older legacy
  /// interface sqlite3_prepare() and sqlite3_prepare16().  The use of the
  /// new "v2" interface is recommended for new applications but the legacy
  /// interface will continue to be supported.
  ///
  /// ^In the legacy interface, the return value will be either [SQLITE_BUSY],
  /// [SQLITE_DONE], [SQLITE_ROW], [SQLITE_ERROR], or [SQLITE_MISUSE].
  /// ^With the "v2" interface, any of the other [result codes] or
  /// [extended result codes] might be returned as well.
  ///
  /// ^[SQLITE_BUSY] means that the database engine was unable to acquire the
  /// database locks it needs to do its job.  ^If the statement is a [COMMIT]
  /// or occurs outside of an explicit transaction, then you can retry the
  /// statement.  If the statement is not a [COMMIT] and occurs within an
  /// explicit transaction then you should rollback the transaction before
  /// continuing.
  ///
  /// ^[SQLITE_DONE] means that the statement has finished executing
  /// successfully.  sqlite3_step() should not be called again on this virtual
  /// machine without first calling [sqlite3_reset()] to reset the virtual
  /// machine back to its initial state.
  ///
  /// ^If the SQL statement being executed returns any data, then [SQLITE_ROW]
  /// is returned each time a new row of data is ready for processing by the
  /// caller. The values may be accessed using the [column access functions].
  /// sqlite3_step() is called again to retrieve the next row of data.
  ///
  /// ^[SQLITE_ERROR] means that a run-time error (such as a constraint
  /// violation) has occurred.  sqlite3_step() should not be called again on
  /// the VM. More information may be found by calling [sqlite3_errmsg()].
  /// ^With the legacy interface, a more specific error code (for example,
  /// [SQLITE_INTERRUPT], [SQLITE_SCHEMA], [SQLITE_CORRUPT], and so forth)
  /// can be obtained by calling [sqlite3_reset()] on the
  /// prepared statement.  ^In the "v2" interface,
  /// the more specific error code is returned directly by sqlite3_step().
  ///
  /// [SQLITE_MISUSE] means that the this routine was called inappropriately.
  /// Perhaps it was called on a prepared statement that has
  /// already been [sqlite3_finalize | finalized] or on one that had
  /// previously returned [SQLITE_ERROR] or [SQLITE_DONE].  Or it could
  /// be the case that the same database connection is being used by two or
  /// more threads at the same moment in time.
  ///
  /// For all versions of SQLite up to and including 3.6.23.1, a call to
  /// [sqlite3_reset] was required after sqlite3_step() returned anything
  /// other than [Errors.SQLITE_ROW] before any subsequent invocation of
  /// sqlite3_step().  Failure to reset the prepared statement using
  /// [sqlite3_reset()] would result in an [Errors.SQLITE_MISUSE] return from
  /// sqlite3_step().  But after version 3.6.23.1, sqlite3_step() began
  /// calling [sqlite3_reset] automatically in this circumstance rather
  /// than returning [Errors.SQLITE_MISUSE]. This is not considered a
  /// compatibility break because any application that ever receives an
  /// [Errors.SQLITE_MISUSE] error is broken by definition.  The
  /// [SQLITE_OMIT_AUTORESET] compile-time option
  /// can be used to restore the legacy behavior.
  ///
  /// <b>Goofy Interface Alert:</b> In the legacy interface, the sqlite3_step()
  /// API always returns a generic error code, [SQLITE_ERROR], following any
  /// error other than [SQLITE_BUSY] and [SQLITE_MISUSE].  You must call
  /// [sqlite3_reset()] or [sqlite3_finalize()] in order to find one of the
  /// specific [error codes] that better describes the error.
  /// We admit that this is a goofy design.  The problem has been fixed
  /// with the "v2" interface.  If you prepare all of your SQL statements
  /// using either [sqlite3_prepare_v2()] or [sqlite3_prepare16_v2()] instead
  /// of the legacy [sqlite3_prepare()] and [sqlite3_prepare16()] interfaces,
  /// then the more specific [error codes] are returned directly
  /// by sqlite3_step().  The use of the "v2" interface is recommended.
  int Function(Pointer<Statement> statement) sqlite3_step;

  /// CAPI3REF: Reset A Prepared Statement Object
  ///
  /// The sqlite3_reset() function is called to reset a prepared statement
  /// object back to its initial state, ready to be re-executed.
  /// ^Any SQL statement variables that had values bound to them using
  /// the sqlite3_bind_blob | sqlite3_bind_*() API retain their values.
  /// Use sqlite3_clear_bindings() to reset the bindings.
  ///
  /// ^The [sqlite3_reset] interface resets the prepared statement S
  /// back to the beginning of its program.
  ///
  /// ^If the most recent call to [sqlite3_step] for the
  /// prepared statement S returned [Errors.SQLITE_ROW] or [Errors.SQLITE_DONE],
  /// or if [sqlite3_step] has never before been called on S,
  /// then [sqlite3_reset] returns [Errors.SQLITE_OK].
  ///
  /// ^If the most recent call to [sqlite3_step(S)] for the
  /// prepared statement S indicated an error, then
  /// [sqlite3_reset] returns an appropriate [Errors].
  ///
  /// ^The [sqlite3_reset] interface does not change the values
  int Function(Pointer<Statement> statement) sqlite3_reset;

  /// Destroy A Prepared Statement Object
  ///
  /// ^The sqlite3_finalize() function is called to delete a prepared statement.
  /// ^If the most recent evaluation of the statement encountered no errors
  /// or if the statement is never been evaluated, then sqlite3_finalize()
  /// returns SQLITE_OK.  ^If the most recent evaluation of statement S failed,
  /// then sqlite3_finalize(S) returns the appropriate error code or extended
  /// error code.
  ///
  /// ^The sqlite3_finalize(S) routine can be called at any point during
  /// the life cycle of prepared statement S:
  /// before statement S is ever evaluated, after
  /// one or more calls to [sqlite3_reset], or after any call
  /// to [sqlite3_step] regardless of whether or not the statement has
  /// completed execution.
  ///
  /// ^Invoking sqlite3_finalize() on a NULL pointer is a harmless no-op.
  ///
  /// The application must finalize every prepared statement in order to avoid
  /// resource leaks.  It is a grievous error for the application to try to use
  /// a prepared statement after it has been finalized.  Any use of a prepared
  /// statement after it has been finalized can result in undefined and
  /// undesirable behavior such as segfaults and heap corruption.
  int Function(Pointer<Statement> statement) sqlite3_finalize;

  /// Number Of Columns In A Result Set
  ///
  /// ^Return the number of columns in the result set returned by the
  /// prepared statement. ^This routine returns 0 if pStmt is an SQL
  /// statement that does not return data (for example an [UPDATE]).
  int Function(Pointer<Statement> statement) sqlite3_column_count;

  /// Column Names In A Result Set
  ///
  /// ^These routines return the name assigned to a particular column
  /// in the result set of a SELECT statement.  ^The sqlite3_column_name()
  /// interface returns a pointer to a zero-terminated UTF-8 string
  /// and sqlite3_column_name16() returns a pointer to a zero-terminated
  /// UTF-16 string.  ^The first parameter is the prepared statement
  /// that implements the SELECT statement. ^The second parameter is the
  /// column number.  ^The leftmost column is number 0.
  ///
  /// ^The returned string pointer is valid until either the prepared statement
  /// is destroyed by [sqlite3_finalize] or until the statement is automatically
  /// reprepared by the first call to [sqlite3_step] for a particular run
  /// or until the next call to
  /// sqlite3_column_name() or sqlite3_column_name16() on the same column.
  ///
  /// ^If sqlite3_malloc() fails during the processing of either routine
  /// (for example during a conversion from UTF-8 to UTF-16) then a
  /// NULL pointer is returned.
  ///
  /// ^The name of a result column is the value of the "AS" clause for
  /// that column, if there is an AS clause.  If there is no AS clause
  /// then the name of the column is unspecified and may change from
  Pointer<Utf8> Function(Pointer<Statement> statement, int columnIndex)
      sqlite3_column_name;

  /// CAPI3REF: Declared Datatype Of A Query Result
  ///
  /// ^(The first parameter is a prepared statement.
  /// If this statement is a SELECT statement and the Nth column of the
  /// returned result set of that SELECT is a table column (not an
  /// expression or subquery) then the declared type of the table
  /// column is returned.)^  ^If the Nth column of the result set is an
  /// expression or subquery, then a NULL pointer is returned.
  /// ^The returned string is always UTF-8 encoded.
  ///
  /// ^(For example, given the database schema:
  ///
  /// CREATE TABLE t1(c1 VARIANT);
  ///
  /// and the following statement to be compiled:
  ///
  /// SELECT c1 + 1, c1 FROM t1;
  ///
  /// this routine would return the string "VARIANT" for the second result
  /// column (i==1), and a NULL pointer for the first result column (i==0).)^
  ///
  /// ^SQLite uses dynamic run-time typing.  ^So just because a column
  /// is declared to contain a particular type does not mean that the
  /// data stored in that column is of the declared type.  SQLite is
  /// strongly typed, but the typing is dynamic not static.  ^Type
  /// is associated with individual values, not with the containers
  /// used to hold those values.
  Pointer<Utf8> Function(Pointer<Statement> statement, int columnIndex)
      sqlite3_column_decltype;

  int Function(Pointer<Statement> statement, int columnIndex)
      sqlite3_column_type;

  Pointer<Value> Function(Pointer<Statement> statement, int columnIndex)
      sqlite3_column_value;

  double Function(Pointer<Statement> statement, int columnIndex)
      sqlite3_column_double;

  int Function(Pointer<Statement> statement, int columnIndex)
      sqlite3_column_int;

  Pointer<Utf8> Function(Pointer<Statement> statement, int columnIndex)
      sqlite3_column_text;

  /// The sqlite3_errstr() interface returns the English-language text that
  /// describes the result code, as UTF-8. Memory to hold the error message
  /// string is managed internally and must not be freed by the application.
  Pointer<Utf8> Function(int code) sqlite3_errstr;

  /// Error Codes And Messages
  ///
  /// ^The sqlite3_errcode() interface returns the numeric [result code] or
  /// [extended result code] for the most recent failed sqlite3_* API call
  /// associated with a [database connection]. If a prior API call failed
  /// but the most recent API call succeeded, the return value from
  /// sqlite3_errcode() is undefined.  ^The sqlite3_extended_errcode()
  /// interface is the same except that it always returns the
  /// [extended result code] even when extended result codes are
  /// disabled.
  ///
  /// ^The sqlite3_errmsg() and sqlite3_errmsg16() return English-language
  /// text that describes the error, as either UTF-8 or UTF-16 respectively.
  /// ^(Memory to hold the error message string is managed internally.
  /// The application does not need to worry about freeing the result.
  /// However, the error string might be overwritten or deallocated by
  /// subsequent calls to other SQLite interface functions.)^
  ///
  /// When the serialized [threading mode] is in use, it might be the
  /// case that a second error occurs on a separate thread in between
  /// the time of the first error and the call to these interfaces.
  /// When that happens, the second error will be reported since these
  /// interfaces always report the most recent result.  To avoid
  /// this, each thread can obtain exclusive use of the [database connection] D
  /// by invoking [sqlite3_mutex_enter]([sqlite3_db_mutex](D)) before beginning
  /// to use D and invoking [sqlite3_mutex_leave]([sqlite3_db_mutex](D)) after
  /// all calls to the interfaces listed here are completed.
  ///
  /// If an interface fails with SQLITE_MISUSE, that means the interface
  /// was invoked incorrectly by the application.  In that case, the
  /// error code and message may or may not be set.
  Pointer<Utf8> Function(Pointer<Database> database) sqlite3_errmsg;

  _SQLiteBindings() {
    sqlite = dlopenPlatformSpecific("sqlite3");
    sqlite3_open_v2 = sqlite
        .lookup<NativeFunction<sqlite3_open_v2_native_t>>("sqlite3_open_v2")
        .asFunction();
    sqlite3_close_v2 = sqlite
        .lookup<NativeFunction<sqlite3_close_v2_native_t>>("sqlite3_close_v2")
        .asFunction();
    sqlite3_prepare_v2 = sqlite
        .lookup<NativeFunction<sqlite3_prepare_v2_native_t>>(
            "sqlite3_prepare_v2")
        .asFunction();
    sqlite3_step = sqlite
        .lookup<NativeFunction<sqlite3_step_native_t>>("sqlite3_step")
        .asFunction();
    sqlite3_reset = sqlite
        .lookup<NativeFunction<sqlite3_reset_native_t>>("sqlite3_reset")
        .asFunction();
    sqlite3_finalize = sqlite
        .lookup<NativeFunction<sqlite3_finalize_native_t>>("sqlite3_finalize")
        .asFunction();
    sqlite3_errstr = sqlite
        .lookup<NativeFunction<sqlite3_errstr_native_t>>("sqlite3_errstr")
        .asFunction();
    sqlite3_errmsg = sqlite
        .lookup<NativeFunction<sqlite3_errmsg_native_t>>("sqlite3_errmsg")
        .asFunction();
    sqlite3_column_count = sqlite
        .lookup<NativeFunction<sqlite3_column_count_native_t>>(
            "sqlite3_column_count")
        .asFunction();
    sqlite3_column_name = sqlite
        .lookup<NativeFunction<sqlite3_column_name_native_t>>(
            "sqlite3_column_name")
        .asFunction();
    sqlite3_column_decltype = sqlite
        .lookup<NativeFunction<sqlite3_column_decltype_native_t>>(
            "sqlite3_column_decltype")
        .asFunction();
    sqlite3_column_type = sqlite
        .lookup<NativeFunction<sqlite3_column_type_native_t>>(
            "sqlite3_column_type")
        .asFunction();
    sqlite3_column_value = sqlite
        .lookup<NativeFunction<sqlite3_column_value_native_t>>(
            "sqlite3_column_value")
        .asFunction();
    sqlite3_column_double = sqlite
        .lookup<NativeFunction<sqlite3_column_double_native_t>>(
            "sqlite3_column_double")
        .asFunction();
    sqlite3_column_int = sqlite
        .lookup<NativeFunction<sqlite3_column_int_native_t>>(
            "sqlite3_column_int")
        .asFunction();
    sqlite3_column_text = sqlite
        .lookup<NativeFunction<sqlite3_column_text_native_t>>(
            "sqlite3_column_text")
        .asFunction();
  }
}

_SQLiteBindings _cachedBindings;
_SQLiteBindings get bindings => _cachedBindings ??= _SQLiteBindings();
