// 2001 September 15
//
// The author disclaims copyright to this source code.  In place of
// a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.

import 'dart:ffi' as ffi;

/// SQLite bindings.
class SQLite {
  /// Holds the Dynamic library.
  final ffi.DynamicLibrary _dylib;

  /// The symbols are looked up in [dynamicLibrary].
  SQLite(ffi.DynamicLibrary dynamicLibrary) : _dylib = dynamicLibrary;

  int sqlite3_close_v2(
    ffi.Pointer<sqlite3> arg0,
  ) {
    _sqlite3_close_v2 ??=
        _dylib.lookupFunction<_c_sqlite3_close_v2, _dart_sqlite3_close_v2>(
            'sqlite3_close_v2');
    return _sqlite3_close_v2(
      arg0,
    );
  }

  _dart_sqlite3_close_v2 _sqlite3_close_v2;

  int sqlite3_open_v2(
    ffi.Pointer<ffi.Int8> filename,
    ffi.Pointer<ffi.Pointer<sqlite3>> ppDb,
    int flags,
    ffi.Pointer<ffi.Int8> zVfs,
  ) {
    _sqlite3_open_v2 ??=
        _dylib.lookupFunction<_c_sqlite3_open_v2, _dart_sqlite3_open_v2>(
            'sqlite3_open_v2');
    return _sqlite3_open_v2(
      filename,
      ppDb,
      flags,
      zVfs,
    );
  }

  _dart_sqlite3_open_v2 _sqlite3_open_v2;

  ffi.Pointer<ffi.Int8> sqlite3_errmsg(
    ffi.Pointer<sqlite3> arg0,
  ) {
    _sqlite3_errmsg ??=
        _dylib.lookupFunction<_c_sqlite3_errmsg, _dart_sqlite3_errmsg>(
            'sqlite3_errmsg');
    return _sqlite3_errmsg(
      arg0,
    );
  }

  _dart_sqlite3_errmsg _sqlite3_errmsg;

  ffi.Pointer<ffi.Int8> sqlite3_errstr(
    int arg0,
  ) {
    _sqlite3_errstr ??=
        _dylib.lookupFunction<_c_sqlite3_errstr, _dart_sqlite3_errstr>(
            'sqlite3_errstr');
    return _sqlite3_errstr(
      arg0,
    );
  }

  _dart_sqlite3_errstr _sqlite3_errstr;

  int sqlite3_prepare_v2(
    ffi.Pointer<sqlite3> db,
    ffi.Pointer<ffi.Int8> zSql,
    int nByte,
    ffi.Pointer<ffi.Pointer<sqlite3_stmt>> ppStmt,
    ffi.Pointer<ffi.Pointer<ffi.Int8>> pzTail,
  ) {
    _sqlite3_prepare_v2 ??=
        _dylib.lookupFunction<_c_sqlite3_prepare_v2, _dart_sqlite3_prepare_v2>(
            'sqlite3_prepare_v2');
    return _sqlite3_prepare_v2(
      db,
      zSql,
      nByte,
      ppStmt,
      pzTail,
    );
  }

  _dart_sqlite3_prepare_v2 _sqlite3_prepare_v2;

  /// CAPI3REF: Number Of Columns In A Result Set
  /// METHOD: sqlite3_stmt
  ///
  /// ^Return the number of columns in the result set returned by the
  /// [prepared statement]. ^If this routine returns 0, that means the
  /// [prepared statement] returns no data (for example an [UPDATE]).
  /// ^However, just because this routine returns a positive number does not
  /// mean that one or more rows of data will be returned.  ^A SELECT statement
  /// will always have a positive sqlite3_column_count() but depending on the
  /// WHERE clause constraints and the table content, it might return no rows.
  ///
  /// See also: [sqlite3_data_count()]
  int sqlite3_column_count(
    ffi.Pointer<sqlite3_stmt> pStmt,
  ) {
    _sqlite3_column_count ??= _dylib.lookupFunction<_c_sqlite3_column_count,
        _dart_sqlite3_column_count>('sqlite3_column_count');
    return _sqlite3_column_count(
      pStmt,
    );
  }

  _dart_sqlite3_column_count _sqlite3_column_count;

  /// CAPI3REF: Column Names In A Result Set
  /// METHOD: sqlite3_stmt
  ///
  /// ^These routines return the name assigned to a particular column
  /// in the result set of a [SELECT] statement.  ^The sqlite3_column_name()
  /// interface returns a pointer to a zero-terminated UTF-8 string
  /// and sqlite3_column_name16() returns a pointer to a zero-terminated
  /// UTF-16 string.  ^The first parameter is the [prepared statement]
  /// that implements the [SELECT] statement. ^The second parameter is the
  /// column number.  ^The leftmost column is number 0.
  ///
  /// ^The returned string pointer is valid until either the [prepared statement]
  /// is destroyed by [sqlite3_finalize()] or until the statement is automatically
  /// reprepared by the first call to [sqlite3_step()] for a particular run
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
  /// one release of SQLite to the next.
  ffi.Pointer<ffi.Int8> sqlite3_column_name(
    ffi.Pointer<sqlite3_stmt> arg0,
    int N,
  ) {
    _sqlite3_column_name ??= _dylib.lookupFunction<_c_sqlite3_column_name,
        _dart_sqlite3_column_name>('sqlite3_column_name');
    return _sqlite3_column_name(
      arg0,
      N,
    );
  }

  _dart_sqlite3_column_name _sqlite3_column_name;

  /// CAPI3REF: Declared Datatype Of A Query Result
  /// METHOD: sqlite3_stmt
  ///
  /// ^(The first parameter is a [prepared statement].
  /// If this statement is a [SELECT] statement and the Nth column of the
  /// returned result set of that [SELECT] is a table column (not an
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
  ffi.Pointer<ffi.Int8> sqlite3_column_decltype(
    ffi.Pointer<sqlite3_stmt> arg0,
    int arg1,
  ) {
    _sqlite3_column_decltype ??= _dylib.lookupFunction<
        _c_sqlite3_column_decltype,
        _dart_sqlite3_column_decltype>('sqlite3_column_decltype');
    return _sqlite3_column_decltype(
      arg0,
      arg1,
    );
  }

  _dart_sqlite3_column_decltype _sqlite3_column_decltype;

  /// CAPI3REF: Evaluate An SQL Statement
  /// METHOD: sqlite3_stmt
  ///
  /// After a [prepared statement] has been prepared using any of
  /// [sqlite3_prepare_v2()], [sqlite3_prepare_v3()], [sqlite3_prepare16_v2()],
  /// or [sqlite3_prepare16_v3()] or one of the legacy
  /// interfaces [sqlite3_prepare()] or [sqlite3_prepare16()], this function
  /// must be called one or more times to evaluate the statement.
  ///
  /// The details of the behavior of the sqlite3_step() interface depend
  /// on whether the statement was prepared using the newer "vX" interfaces
  /// [sqlite3_prepare_v3()], [sqlite3_prepare_v2()], [sqlite3_prepare16_v3()],
  /// [sqlite3_prepare16_v2()] or the older legacy
  /// interfaces [sqlite3_prepare()] and [sqlite3_prepare16()].  The use of the
  /// new "vX" interface is recommended for new applications but the legacy
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
  /// [prepared statement].  ^In the "v2" interface,
  /// the more specific error code is returned directly by sqlite3_step().
  ///
  /// [SQLITE_MISUSE] means that the this routine was called inappropriately.
  /// Perhaps it was called on a [prepared statement] that has
  /// already been [sqlite3_finalize | finalized] or on one that had
  /// previously returned [SQLITE_ERROR] or [SQLITE_DONE].  Or it could
  /// be the case that the same database connection is being used by two or
  /// more threads at the same moment in time.
  ///
  /// For all versions of SQLite up to and including 3.6.23.1, a call to
  /// [sqlite3_reset()] was required after sqlite3_step() returned anything
  /// other than [SQLITE_ROW] before any subsequent invocation of
  /// sqlite3_step().  Failure to reset the prepared statement using
  /// [sqlite3_reset()] would result in an [SQLITE_MISUSE] return from
  /// sqlite3_step().  But after [version 3.6.23.1] ([dateof:3.6.23.1],
  /// sqlite3_step() began
  /// calling [sqlite3_reset()] automatically in this circumstance rather
  /// than returning [SQLITE_MISUSE].  This is not considered a compatibility
  /// break because any application that ever receives an SQLITE_MISUSE error
  /// is broken by definition.  The [SQLITE_OMIT_AUTORESET] compile-time option
  /// can be used to restore the legacy behavior.
  ///
  /// <b>Goofy Interface Alert:</b> In the legacy interface, the sqlite3_step()
  /// API always returns a generic error code, [SQLITE_ERROR], following any
  /// error other than [SQLITE_BUSY] and [SQLITE_MISUSE].  You must call
  /// [sqlite3_reset()] or [sqlite3_finalize()] in order to find one of the
  /// specific [error codes] that better describes the error.
  /// We admit that this is a goofy design.  The problem has been fixed
  /// with the "v2" interface.  If you prepare all of your SQL statements
  /// using [sqlite3_prepare_v3()] or [sqlite3_prepare_v2()]
  /// or [sqlite3_prepare16_v2()] or [sqlite3_prepare16_v3()] instead
  /// of the legacy [sqlite3_prepare()] and [sqlite3_prepare16()] interfaces,
  /// then the more specific [error codes] are returned directly
  /// by sqlite3_step().  The use of the "vX" interfaces is recommended.
  int sqlite3_step(
    ffi.Pointer<sqlite3_stmt> arg0,
  ) {
    _sqlite3_step ??= _dylib
        .lookupFunction<_c_sqlite3_step, _dart_sqlite3_step>('sqlite3_step');
    return _sqlite3_step(
      arg0,
    );
  }

  _dart_sqlite3_step _sqlite3_step;

  int sqlite3_column_int(
    ffi.Pointer<sqlite3_stmt> arg0,
    int iCol,
  ) {
    _sqlite3_column_int ??=
        _dylib.lookupFunction<_c_sqlite3_column_int, _dart_sqlite3_column_int>(
            'sqlite3_column_int');
    return _sqlite3_column_int(
      arg0,
      iCol,
    );
  }

  _dart_sqlite3_column_int _sqlite3_column_int;

  ffi.Pointer<ffi.Uint8> sqlite3_column_text(
    ffi.Pointer<sqlite3_stmt> arg0,
    int iCol,
  ) {
    _sqlite3_column_text ??= _dylib.lookupFunction<_c_sqlite3_column_text,
        _dart_sqlite3_column_text>('sqlite3_column_text');
    return _sqlite3_column_text(
      arg0,
      iCol,
    );
  }

  _dart_sqlite3_column_text _sqlite3_column_text;

  int sqlite3_column_type(
    ffi.Pointer<sqlite3_stmt> arg0,
    int iCol,
  ) {
    _sqlite3_column_type ??= _dylib.lookupFunction<_c_sqlite3_column_type,
        _dart_sqlite3_column_type>('sqlite3_column_type');
    return _sqlite3_column_type(
      arg0,
      iCol,
    );
  }

  _dart_sqlite3_column_type _sqlite3_column_type;

  /// CAPI3REF: Destroy A Prepared Statement Object
  /// DESTRUCTOR: sqlite3_stmt
  ///
  /// ^The sqlite3_finalize() function is called to delete a [prepared statement].
  /// ^If the most recent evaluation of the statement encountered no errors
  /// or if the statement is never been evaluated, then sqlite3_finalize() returns
  /// SQLITE_OK.  ^If the most recent evaluation of statement S failed, then
  /// sqlite3_finalize(S) returns the appropriate [error code] or
  /// [extended error code].
  ///
  /// ^The sqlite3_finalize(S) routine can be called at any point during
  /// the life cycle of [prepared statement] S:
  /// before statement S is ever evaluated, after
  /// one or more calls to [sqlite3_reset()], or after any call
  /// to [sqlite3_step()] regardless of whether or not the statement has
  /// completed execution.
  ///
  /// ^Invoking sqlite3_finalize() on a NULL pointer is a harmless no-op.
  ///
  /// The application must finalize every [prepared statement] in order to avoid
  /// resource leaks.  It is a grievous error for the application to try to use
  /// a prepared statement after it has been finalized.  Any use of a prepared
  /// statement after it has been finalized can result in undefined and
  /// undesirable behavior such as segfaults and heap corruption.
  int sqlite3_finalize(
    ffi.Pointer<sqlite3_stmt> pStmt,
  ) {
    _sqlite3_finalize ??=
        _dylib.lookupFunction<_c_sqlite3_finalize, _dart_sqlite3_finalize>(
            'sqlite3_finalize');
    return _sqlite3_finalize(
      pStmt,
    );
  }

  _dart_sqlite3_finalize _sqlite3_finalize;
}

class sqlite3 extends ffi.Struct {}

class sqlite3_file extends ffi.Struct {}

class sqlite3_io_methods extends ffi.Struct {
  @ffi.Int32()
  int iVersion;

  ffi.Pointer<ffi.NativeFunction<_typedefC_1>> xClose;

  ffi.Pointer<ffi.NativeFunction<_typedefC_2>> xRead;

  ffi.Pointer<ffi.NativeFunction<_typedefC_3>> xWrite;

  ffi.Pointer<ffi.NativeFunction<_typedefC_4>> xTruncate;

  ffi.Pointer<ffi.NativeFunction<_typedefC_5>> xSync;

  ffi.Pointer<ffi.NativeFunction<_typedefC_6>> xFileSize;

  ffi.Pointer<ffi.NativeFunction<_typedefC_7>> xLock;

  ffi.Pointer<ffi.NativeFunction<_typedefC_8>> xUnlock;

  ffi.Pointer<ffi.NativeFunction<_typedefC_9>> xCheckReservedLock;

  ffi.Pointer<ffi.NativeFunction<_typedefC_10>> xFileControl;

  ffi.Pointer<ffi.NativeFunction<_typedefC_11>> xSectorSize;

  ffi.Pointer<ffi.NativeFunction<_typedefC_12>> xDeviceCharacteristics;

  /// Methods above are valid for version 1
  ffi.Pointer<ffi.NativeFunction<_typedefC_13>> xShmMap;

  ffi.Pointer<ffi.NativeFunction<_typedefC_14>> xShmLock;

  ffi.Pointer<ffi.NativeFunction<_typedefC_15>> xShmBarrier;

  ffi.Pointer<ffi.NativeFunction<_typedefC_16>> xShmUnmap;

  /// Methods above are valid for version 2
  ffi.Pointer<ffi.NativeFunction<_typedefC_17>> xFetch;

  ffi.Pointer<ffi.NativeFunction<_typedefC_18>> xUnfetch;
}

class sqlite3_mutex extends ffi.Struct {}

class sqlite3_api_routines extends ffi.Struct {}

class sqlite3_vfs extends ffi.Struct {}

class sqlite3_mem_methods extends ffi.Struct {}

class sqlite3_stmt extends ffi.Struct {}

class sqlite3_value extends ffi.Struct {}

class sqlite3_context extends ffi.Struct {}

/// CAPI3REF: Virtual Table Instance Object
/// KEYWORDS: sqlite3_vtab
///
/// Every [virtual table module] implementation uses a subclass
/// of this object to describe a particular instance
/// of the [virtual table].  Each subclass will
/// be tailored to the specific needs of the module implementation.
/// The purpose of this superclass is to define certain fields that are
/// common to all module implementations.
///
/// ^Virtual tables methods can set an error message by assigning a
/// string obtained from [sqlite3_mprintf()] to zErrMsg.  The method should
/// take care that any prior string is freed by a call to [sqlite3_free()]
/// prior to assigning a new string to zErrMsg.  ^After the error message
/// is delivered up to the client application, the string will be automatically
/// freed by sqlite3_free() and the zErrMsg field will be zeroed.
class sqlite3_vtab extends ffi.Struct {}

/// CAPI3REF: Virtual Table Indexing Information
/// KEYWORDS: sqlite3_index_info
///
/// The sqlite3_index_info structure and its substructures is used as part
/// of the [virtual table] interface to
/// pass information into and receive the reply from the [xBestIndex]
/// method of a [virtual table module].  The fields under **Inputs** are the
/// inputs to xBestIndex and are read-only.  xBestIndex inserts its
/// results into the **Outputs** fields.
///
/// ^(The aConstraint[] array records WHERE clause constraints of the form:
///
/// <blockquote>column OP expr</blockquote>
///
/// where OP is =, &lt;, &lt;=, &gt;, or &gt;=.)^  ^(The particular operator is
/// stored in aConstraint[].op using one of the
/// [SQLITE_INDEX_CONSTRAINT_EQ | SQLITE_INDEX_CONSTRAINT_ values].)^
/// ^(The index of the column is stored in
/// aConstraint[].iColumn.)^  ^(aConstraint[].usable is TRUE if the
/// expr on the right-hand side can be evaluated (and thus the constraint
/// is usable) and false if it cannot.)^
///
/// ^The optimizer automatically inverts terms of the form "expr OP column"
/// and makes other simplifications to the WHERE clause in an attempt to
/// get as many WHERE clause terms into the form shown above as possible.
/// ^The aConstraint[] array only reports WHERE clause terms that are
/// relevant to the particular virtual table being queried.
///
/// ^Information about the ORDER BY clause is stored in aOrderBy[].
/// ^Each term of aOrderBy records a column of the ORDER BY clause.
///
/// The colUsed field indicates which columns of the virtual table may be
/// required by the current scan. Virtual table columns are numbered from
/// zero in the order in which they appear within the CREATE TABLE statement
/// passed to sqlite3_declare_vtab(). For the first 63 columns (columns 0-62),
/// the corresponding bit is set within the colUsed mask if the column may be
/// required by SQLite. If the table has at least 64 columns and any column
/// to the right of the first 63 is required, then bit 63 of colUsed is also
/// set. In other words, column iCol may be required if the expression
/// (colUsed & ((sqlite3_uint64)1 << (iCol>=63 ? 63 : iCol))) evaluates to
/// non-zero.
///
/// The [xBestIndex] method must fill aConstraintUsage[] with information
/// about what parameters to pass to xFilter.  ^If argvIndex>0 then
/// the right-hand side of the corresponding aConstraint[] is evaluated
/// and becomes the argvIndex-th entry in argv.  ^(If aConstraintUsage[].omit
/// is true, then the constraint is assumed to be fully handled by the
/// virtual table and might not be checked again by the byte code.)^ ^(The
/// aConstraintUsage[].omit flag is an optimization hint. When the omit flag
/// is left in its default setting of false, the constraint will always be
/// checked separately in byte code.  If the omit flag is change to true, then
/// the constraint may or may not be checked in byte code.  In other words,
/// when the omit flag is true there is no guarantee that the constraint will
/// not be checked again using byte code.)^
///
/// ^The idxNum and idxPtr values are recorded and passed into the
/// [xFilter] method.
/// ^[sqlite3_free()] is used to free idxPtr if and only if
/// needToFreeIdxPtr is true.
///
/// ^The orderByConsumed means that output from [xFilter]/[xNext] will occur in
/// the correct order to satisfy the ORDER BY clause so that no separate
/// sorting step is required.
///
/// ^The estimatedCost value is an estimate of the cost of a particular
/// strategy. A cost of N indicates that the cost of the strategy is similar
/// to a linear scan of an SQLite table with N rows. A cost of log(N)
/// indicates that the expense of the operation is similar to that of a
/// binary search on a unique indexed field of an SQLite table with N rows.
///
/// ^The estimatedRows value is an estimate of the number of rows that
/// will be returned by the strategy.
///
/// The xBestIndex method may optionally populate the idxFlags field with a
/// mask of SQLITE_INDEX_SCAN_* flags. Currently there is only one such flag -
/// SQLITE_INDEX_SCAN_UNIQUE. If the xBestIndex method sets this flag, SQLite
/// assumes that the strategy may visit at most one row.
///
/// Additionally, if xBestIndex sets the SQLITE_INDEX_SCAN_UNIQUE flag, then
/// SQLite also assumes that if a call to the xUpdate() method is made as
/// part of the same statement to delete or update a virtual table row and the
/// implementation returns SQLITE_CONSTRAINT, then there is no need to rollback
/// any database changes. In other words, if the xUpdate() returns
/// SQLITE_CONSTRAINT, the database contents must be exactly as they were
/// before xUpdate was called. By contrast, if SQLITE_INDEX_SCAN_UNIQUE is not
/// set and xUpdate returns SQLITE_CONSTRAINT, any database changes made by
/// the xUpdate method are automatically rolled back by SQLite.
///
/// IMPORTANT: The estimatedRows field was added to the sqlite3_index_info
/// structure for SQLite [version 3.8.2] ([dateof:3.8.2]).
/// If a virtual table extension is
/// used with an SQLite version earlier than 3.8.2, the results of attempting
/// to read or write the estimatedRows field are undefined (but are likely
/// to include crashing the application). The estimatedRows field should
/// therefore only be used if [sqlite3_libversion_number()] returns a
/// value greater than or equal to 3008002. Similarly, the idxFlags field
/// was added for [version 3.9.0] ([dateof:3.9.0]).
/// It may therefore only be used if
/// sqlite3_libversion_number() returns a value greater than or equal to
/// 3009000.
class sqlite3_index_info extends ffi.Struct {}

/// CAPI3REF: Virtual Table Cursor Object
/// KEYWORDS: sqlite3_vtab_cursor {virtual table cursor}
///
/// Every [virtual table module] implementation uses a subclass of the
/// following structure to describe cursors that point into the
/// [virtual table] and are used
/// to loop through the virtual table.  Cursors are created using the
/// [sqlite3_module.xOpen | xOpen] method of the module and are destroyed
/// by the [sqlite3_module.xClose | xClose] method.  Cursors are used
/// by the [xFilter], [xNext], [xEof], [xColumn], and [xRowid] methods
/// of the module.  Each module implementation will define
/// the content of a cursor structure to suit its own needs.
///
/// This superclass exists in order to define fields of the cursor that
/// are common to all implementations.
class sqlite3_vtab_cursor extends ffi.Struct {}

/// CAPI3REF: Virtual Table Object
/// KEYWORDS: sqlite3_module {virtual table module}
///
/// This structure, sometimes called a "virtual table module",
/// defines the implementation of a [virtual table].
/// This structure consists mostly of methods for the module.
///
/// ^A virtual table module is created by filling in a persistent
/// instance of this structure and passing a pointer to that instance
/// to [sqlite3_create_module()] or [sqlite3_create_module_v2()].
/// ^The registration remains valid until it is replaced by a different
/// module or until the [database connection] closes.  The content
/// of this structure must not change while it is registered with
/// any database connection.
class sqlite3_module extends ffi.Struct {}

class sqlite3_blob extends ffi.Struct {}

class sqlite3_mutex_methods extends ffi.Struct {}

class sqlite3_str extends ffi.Struct {}

class sqlite3_pcache extends ffi.Struct {}

class sqlite3_pcache_page extends ffi.Struct {}

class sqlite3_pcache_methods2 extends ffi.Struct {}

class sqlite3_pcache_methods extends ffi.Struct {}

class sqlite3_backup extends ffi.Struct {}

/// CAPI3REF: Database Snapshot
/// KEYWORDS: {snapshot} {sqlite3_snapshot}
///
/// An instance of the snapshot object records the state of a [WAL mode]
/// database for some specific point in history.
///
/// In [WAL mode], multiple [database connections] that are open on the
/// same database file can each be reading a different historical version
/// of the database file.  When a [database connection] begins a read
/// transaction, that connection sees an unchanging copy of the database
/// as it existed for the point in time when the transaction first started.
/// Subsequent changes to the database from other connections are not seen
/// by the reader until a new read transaction is started.
///
/// The sqlite3_snapshot object records state information about an historical
/// version of the database file so that it is possible to later open a new read
/// transaction that sees that historical version of the database rather than
/// the most recent version.
class sqlite3_snapshot extends ffi.Struct {}

/// A pointer to a structure of the following type is passed as the first
/// argument to callbacks registered using rtree_geometry_callback().
class sqlite3_rtree_geometry extends ffi.Struct {}

/// A pointer to a structure of the following type is passed as the
/// argument to scored geometry callback registered using
/// sqlite3_rtree_query_callback().
///
/// Note that the first 5 fields of this structure are identical to
/// sqlite3_rtree_geometry.  This structure is a subclass of
/// sqlite3_rtree_geometry.
class sqlite3_rtree_query_info extends ffi.Struct {}

/// EXTENSION API FUNCTIONS
///
/// xUserData(pFts):
/// Return a copy of the context pointer the extension function was
/// registered with.
///
/// xColumnTotalSize(pFts, iCol, pnToken):
/// If parameter iCol is less than zero, set output variable *pnToken
/// to the total number of tokens in the FTS5 table. Or, if iCol is
/// non-negative but less than the number of columns in the table, return
/// the total number of tokens in column iCol, considering all rows in
/// the FTS5 table.
///
/// If parameter iCol is greater than or equal to the number of columns
/// in the table, SQLITE_RANGE is returned. Or, if an error occurs (e.g.
/// an OOM condition or IO error), an appropriate SQLite error code is
/// returned.
///
/// xColumnCount(pFts):
/// Return the number of columns in the table.
///
/// xColumnSize(pFts, iCol, pnToken):
/// If parameter iCol is less than zero, set output variable *pnToken
/// to the total number of tokens in the current row. Or, if iCol is
/// non-negative but less than the number of columns in the table, set
/// *pnToken to the number of tokens in column iCol of the current row.
///
/// If parameter iCol is greater than or equal to the number of columns
/// in the table, SQLITE_RANGE is returned. Or, if an error occurs (e.g.
/// an OOM condition or IO error), an appropriate SQLite error code is
/// returned.
///
/// This function may be quite inefficient if used with an FTS5 table
/// created with the "columnsize=0" option.
///
/// xColumnText:
/// This function attempts to retrieve the text of column iCol of the
/// current document. If successful, (*pz) is set to point to a buffer
/// containing the text in utf-8 encoding, (*pn) is set to the size in bytes
/// (not characters) of the buffer and SQLITE_OK is returned. Otherwise,
/// if an error occurs, an SQLite error code is returned and the final values
/// of (*pz) and (*pn) are undefined.
///
/// xPhraseCount:
/// Returns the number of phrases in the current query expression.
///
/// xPhraseSize:
/// Returns the number of tokens in phrase iPhrase of the query. Phrases
/// are numbered starting from zero.
///
/// xInstCount:
/// Set *pnInst to the total number of occurrences of all phrases within
/// the query within the current row. Return SQLITE_OK if successful, or
/// an error code (i.e. SQLITE_NOMEM) if an error occurs.
///
/// This API can be quite slow if used with an FTS5 table created with the
/// "detail=none" or "detail=column" option. If the FTS5 table is created
/// with either "detail=none" or "detail=column" and "content=" option
/// (i.e. if it is a contentless table), then this API always returns 0.
///
/// xInst:
/// Query for the details of phrase match iIdx within the current row.
/// Phrase matches are numbered starting from zero, so the iIdx argument
/// should be greater than or equal to zero and smaller than the value
/// output by xInstCount().
///
/// Usually, output parameter *piPhrase is set to the phrase number, *piCol
/// to the column in which it occurs and *piOff the token offset of the
/// first token of the phrase. Returns SQLITE_OK if successful, or an error
/// code (i.e. SQLITE_NOMEM) if an error occurs.
///
/// This API can be quite slow if used with an FTS5 table created with the
/// "detail=none" or "detail=column" option.
///
/// xRowid:
/// Returns the rowid of the current row.
///
/// xTokenize:
/// Tokenize text using the tokenizer belonging to the FTS5 table.
///
/// xQueryPhrase(pFts5, iPhrase, pUserData, xCallback):
/// This API function is used to query the FTS table for phrase iPhrase
/// of the current query. Specifically, a query equivalent to:
///
/// ... FROM ftstable WHERE ftstable MATCH $p ORDER BY rowid
///
/// with $p set to a phrase equivalent to the phrase iPhrase of the
/// current query is executed. Any column filter that applies to
/// phrase iPhrase of the current query is included in $p. For each
/// row visited, the callback function passed as the fourth argument
/// is invoked. The context and API objects passed to the callback
/// function may be used to access the properties of each matched row.
/// Invoking Api.xUserData() returns a copy of the pointer passed as
/// the third argument to pUserData.
///
/// If the callback function returns any value other than SQLITE_OK, the
/// query is abandoned and the xQueryPhrase function returns immediately.
/// If the returned value is SQLITE_DONE, xQueryPhrase returns SQLITE_OK.
/// Otherwise, the error code is propagated upwards.
///
/// If the query runs to completion without incident, SQLITE_OK is returned.
/// Or, if some error occurs before the query completes or is aborted by
/// the callback, an SQLite error code is returned.
///
///
/// xSetAuxdata(pFts5, pAux, xDelete)
///
/// Save the pointer passed as the second argument as the extension function's
/// "auxiliary data". The pointer may then be retrieved by the current or any
/// future invocation of the same fts5 extension function made as part of
/// the same MATCH query using the xGetAuxdata() API.
///
/// Each extension function is allocated a single auxiliary data slot for
/// each FTS query (MATCH expression). If the extension function is invoked
/// more than once for a single FTS query, then all invocations share a
/// single auxiliary data context.
///
/// If there is already an auxiliary data pointer when this function is
/// invoked, then it is replaced by the new pointer. If an xDelete callback
/// was specified along with the original pointer, it is invoked at this
/// point.
///
/// The xDelete callback, if one is specified, is also invoked on the
/// auxiliary data pointer after the FTS5 query has finished.
///
/// If an error (e.g. an OOM condition) occurs within this function,
/// the auxiliary data is set to NULL and an error code returned. If the
/// xDelete parameter was not NULL, it is invoked on the auxiliary data
/// pointer before returning.
///
///
/// xGetAuxdata(pFts5, bClear)
///
/// Returns the current auxiliary data pointer for the fts5 extension
/// function. See the xSetAuxdata() method for details.
///
/// If the bClear argument is non-zero, then the auxiliary data is cleared
/// (set to NULL) before this function returns. In this case the xDelete,
/// if any, is not invoked.
///
///
/// xRowCount(pFts5, pnRow)
///
/// This function is used to retrieve the total number of rows in the table.
/// In other words, the same value that would be returned by:
///
/// SELECT count(*) FROM ftstable;
///
/// xPhraseFirst()
/// This function is used, along with type Fts5PhraseIter and the xPhraseNext
/// method, to iterate through all instances of a single query phrase within
/// the current row. This is the same information as is accessible via the
/// xInstCount/xInst APIs. While the xInstCount/xInst APIs are more convenient
/// to use, this API may be faster under some circumstances. To iterate
/// through instances of phrase iPhrase, use the following code:
///
/// Fts5PhraseIter iter;
/// int iCol, iOff;
/// for(pApi->xPhraseFirst(pFts, iPhrase, &iter, &iCol, &iOff);
/// iCol>=0;
/// pApi->xPhraseNext(pFts, &iter, &iCol, &iOff)
/// ){
/// // An instance of phrase iPhrase at offset iOff of column iCol
/// }
///
/// The Fts5PhraseIter structure is defined above. Applications should not
/// modify this structure directly - it should only be used as shown above
/// with the xPhraseFirst() and xPhraseNext() API methods (and by
/// xPhraseFirstColumn() and xPhraseNextColumn() as illustrated below).
///
/// This API can be quite slow if used with an FTS5 table created with the
/// "detail=none" or "detail=column" option. If the FTS5 table is created
/// with either "detail=none" or "detail=column" and "content=" option
/// (i.e. if it is a contentless table), then this API always iterates
/// through an empty set (all calls to xPhraseFirst() set iCol to -1).
///
/// xPhraseNext()
/// See xPhraseFirst above.
///
/// xPhraseFirstColumn()
/// This function and xPhraseNextColumn() are similar to the xPhraseFirst()
/// and xPhraseNext() APIs described above. The difference is that instead
/// of iterating through all instances of a phrase in the current row, these
/// APIs are used to iterate through the set of columns in the current row
/// that contain one or more instances of a specified phrase. For example:
///
/// Fts5PhraseIter iter;
/// int iCol;
/// for(pApi->xPhraseFirstColumn(pFts, iPhrase, &iter, &iCol);
/// iCol>=0;
/// pApi->xPhraseNextColumn(pFts, &iter, &iCol)
/// ){
/// // Column iCol contains at least one instance of phrase iPhrase
/// }
///
/// This API can be quite slow if used with an FTS5 table created with the
/// "detail=none" option. If the FTS5 table is created with either
/// "detail=none" "content=" option (i.e. if it is a contentless table),
/// then this API always iterates through an empty set (all calls to
/// xPhraseFirstColumn() set iCol to -1).
///
/// The information accessed using this API and its companion
/// xPhraseFirstColumn() may also be obtained using xPhraseFirst/xPhraseNext
/// (or xInst/xInstCount). The chief advantage of this API is that it is
/// significantly more efficient than those alternatives when used with
/// "detail=column" tables.
///
/// xPhraseNextColumn()
/// See xPhraseFirstColumn above.
class Fts5ExtensionApi extends ffi.Struct {}

class Fts5Context extends ffi.Struct {}

class Fts5PhraseIter extends ffi.Struct {}

class Fts5Tokenizer extends ffi.Struct {}

class fts5_tokenizer extends ffi.Struct {}

class fts5_api extends ffi.Struct {}

const String SQLITE_VERSION = '3.32.3';

const int SQLITE_VERSION_NUMBER = 3032003;

const String SQLITE_SOURCE_ID =
    '2020-06-18 14:00:33 7ebdfa80be8e8e73324b8d66b3460222eb74c7e9dfd655b48d6ca7e1933cc8fd';

const int SQLITE_OK = 0;

const int SQLITE_ERROR = 1;

const int SQLITE_INTERNAL = 2;

const int SQLITE_PERM = 3;

const int SQLITE_ABORT = 4;

const int SQLITE_BUSY = 5;

const int SQLITE_LOCKED = 6;

const int SQLITE_NOMEM = 7;

const int SQLITE_READONLY = 8;

const int SQLITE_INTERRUPT = 9;

const int SQLITE_IOERR = 10;

const int SQLITE_CORRUPT = 11;

const int SQLITE_NOTFOUND = 12;

const int SQLITE_FULL = 13;

const int SQLITE_CANTOPEN = 14;

const int SQLITE_PROTOCOL = 15;

const int SQLITE_EMPTY = 16;

const int SQLITE_SCHEMA = 17;

const int SQLITE_TOOBIG = 18;

const int SQLITE_CONSTRAINT = 19;

const int SQLITE_MISMATCH = 20;

const int SQLITE_MISUSE = 21;

const int SQLITE_NOLFS = 22;

const int SQLITE_AUTH = 23;

const int SQLITE_FORMAT = 24;

const int SQLITE_RANGE = 25;

const int SQLITE_NOTADB = 26;

const int SQLITE_NOTICE = 27;

const int SQLITE_WARNING = 28;

const int SQLITE_ROW = 100;

const int SQLITE_DONE = 101;

const int SQLITE_ERROR_MISSING_COLLSEQ = 257;

const int SQLITE_ERROR_RETRY = 513;

const int SQLITE_ERROR_SNAPSHOT = 769;

const int SQLITE_IOERR_READ = 266;

const int SQLITE_IOERR_SHORT_READ = 522;

const int SQLITE_IOERR_WRITE = 778;

const int SQLITE_IOERR_FSYNC = 1034;

const int SQLITE_IOERR_DIR_FSYNC = 1290;

const int SQLITE_IOERR_TRUNCATE = 1546;

const int SQLITE_IOERR_FSTAT = 1802;

const int SQLITE_IOERR_UNLOCK = 2058;

const int SQLITE_IOERR_RDLOCK = 2314;

const int SQLITE_IOERR_DELETE = 2570;

const int SQLITE_IOERR_BLOCKED = 2826;

const int SQLITE_IOERR_NOMEM = 3082;

const int SQLITE_IOERR_ACCESS = 3338;

const int SQLITE_IOERR_CHECKRESERVEDLOCK = 3594;

const int SQLITE_IOERR_LOCK = 3850;

const int SQLITE_IOERR_CLOSE = 4106;

const int SQLITE_IOERR_DIR_CLOSE = 4362;

const int SQLITE_IOERR_SHMOPEN = 4618;

const int SQLITE_IOERR_SHMSIZE = 4874;

const int SQLITE_IOERR_SHMLOCK = 5130;

const int SQLITE_IOERR_SHMMAP = 5386;

const int SQLITE_IOERR_SEEK = 5642;

const int SQLITE_IOERR_DELETE_NOENT = 5898;

const int SQLITE_IOERR_MMAP = 6154;

const int SQLITE_IOERR_GETTEMPPATH = 6410;

const int SQLITE_IOERR_CONVPATH = 6666;

const int SQLITE_IOERR_VNODE = 6922;

const int SQLITE_IOERR_AUTH = 7178;

const int SQLITE_IOERR_BEGIN_ATOMIC = 7434;

const int SQLITE_IOERR_COMMIT_ATOMIC = 7690;

const int SQLITE_IOERR_ROLLBACK_ATOMIC = 7946;

const int SQLITE_IOERR_DATA = 8202;

const int SQLITE_LOCKED_SHAREDCACHE = 262;

const int SQLITE_LOCKED_VTAB = 518;

const int SQLITE_BUSY_RECOVERY = 261;

const int SQLITE_BUSY_SNAPSHOT = 517;

const int SQLITE_BUSY_TIMEOUT = 773;

const int SQLITE_CANTOPEN_NOTEMPDIR = 270;

const int SQLITE_CANTOPEN_ISDIR = 526;

const int SQLITE_CANTOPEN_FULLPATH = 782;

const int SQLITE_CANTOPEN_CONVPATH = 1038;

const int SQLITE_CANTOPEN_DIRTYWAL = 1294;

const int SQLITE_CANTOPEN_SYMLINK = 1550;

const int SQLITE_CORRUPT_VTAB = 267;

const int SQLITE_CORRUPT_SEQUENCE = 523;

const int SQLITE_CORRUPT_INDEX = 779;

const int SQLITE_READONLY_RECOVERY = 264;

const int SQLITE_READONLY_CANTLOCK = 520;

const int SQLITE_READONLY_ROLLBACK = 776;

const int SQLITE_READONLY_DBMOVED = 1032;

const int SQLITE_READONLY_CANTINIT = 1288;

const int SQLITE_READONLY_DIRECTORY = 1544;

const int SQLITE_ABORT_ROLLBACK = 516;

const int SQLITE_CONSTRAINT_CHECK = 275;

const int SQLITE_CONSTRAINT_COMMITHOOK = 531;

const int SQLITE_CONSTRAINT_FOREIGNKEY = 787;

const int SQLITE_CONSTRAINT_FUNCTION = 1043;

const int SQLITE_CONSTRAINT_NOTNULL = 1299;

const int SQLITE_CONSTRAINT_PRIMARYKEY = 1555;

const int SQLITE_CONSTRAINT_TRIGGER = 1811;

const int SQLITE_CONSTRAINT_UNIQUE = 2067;

const int SQLITE_CONSTRAINT_VTAB = 2323;

const int SQLITE_CONSTRAINT_ROWID = 2579;

const int SQLITE_CONSTRAINT_PINNED = 2835;

const int SQLITE_NOTICE_RECOVER_WAL = 283;

const int SQLITE_NOTICE_RECOVER_ROLLBACK = 539;

const int SQLITE_WARNING_AUTOINDEX = 284;

const int SQLITE_AUTH_USER = 279;

const int SQLITE_OK_LOAD_PERMANENTLY = 256;

const int SQLITE_OK_SYMLINK = 512;

const int SQLITE_OPEN_READONLY = 1;

const int SQLITE_OPEN_READWRITE = 2;

const int SQLITE_OPEN_CREATE = 4;

const int SQLITE_OPEN_DELETEONCLOSE = 8;

const int SQLITE_OPEN_EXCLUSIVE = 16;

const int SQLITE_OPEN_AUTOPROXY = 32;

const int SQLITE_OPEN_URI = 64;

const int SQLITE_OPEN_MEMORY = 128;

const int SQLITE_OPEN_MAIN_DB = 256;

const int SQLITE_OPEN_TEMP_DB = 512;

const int SQLITE_OPEN_TRANSIENT_DB = 1024;

const int SQLITE_OPEN_MAIN_JOURNAL = 2048;

const int SQLITE_OPEN_TEMP_JOURNAL = 4096;

const int SQLITE_OPEN_SUBJOURNAL = 8192;

const int SQLITE_OPEN_MASTER_JOURNAL = 16384;

const int SQLITE_OPEN_NOMUTEX = 32768;

const int SQLITE_OPEN_FULLMUTEX = 65536;

const int SQLITE_OPEN_SHAREDCACHE = 131072;

const int SQLITE_OPEN_PRIVATECACHE = 262144;

const int SQLITE_OPEN_WAL = 524288;

const int SQLITE_OPEN_NOFOLLOW = 16777216;

const int SQLITE_IOCAP_ATOMIC = 1;

const int SQLITE_IOCAP_ATOMIC512 = 2;

const int SQLITE_IOCAP_ATOMIC1K = 4;

const int SQLITE_IOCAP_ATOMIC2K = 8;

const int SQLITE_IOCAP_ATOMIC4K = 16;

const int SQLITE_IOCAP_ATOMIC8K = 32;

const int SQLITE_IOCAP_ATOMIC16K = 64;

const int SQLITE_IOCAP_ATOMIC32K = 128;

const int SQLITE_IOCAP_ATOMIC64K = 256;

const int SQLITE_IOCAP_SAFE_APPEND = 512;

const int SQLITE_IOCAP_SEQUENTIAL = 1024;

const int SQLITE_IOCAP_UNDELETABLE_WHEN_OPEN = 2048;

const int SQLITE_IOCAP_POWERSAFE_OVERWRITE = 4096;

const int SQLITE_IOCAP_IMMUTABLE = 8192;

const int SQLITE_IOCAP_BATCH_ATOMIC = 16384;

const int SQLITE_LOCK_NONE = 0;

const int SQLITE_LOCK_SHARED = 1;

const int SQLITE_LOCK_RESERVED = 2;

const int SQLITE_LOCK_PENDING = 3;

const int SQLITE_LOCK_EXCLUSIVE = 4;

const int SQLITE_SYNC_NORMAL = 2;

const int SQLITE_SYNC_FULL = 3;

const int SQLITE_SYNC_DATAONLY = 16;

const int SQLITE_FCNTL_LOCKSTATE = 1;

const int SQLITE_FCNTL_GET_LOCKPROXYFILE = 2;

const int SQLITE_FCNTL_SET_LOCKPROXYFILE = 3;

const int SQLITE_FCNTL_LAST_ERRNO = 4;

const int SQLITE_FCNTL_SIZE_HINT = 5;

const int SQLITE_FCNTL_CHUNK_SIZE = 6;

const int SQLITE_FCNTL_FILE_POINTER = 7;

const int SQLITE_FCNTL_SYNC_OMITTED = 8;

const int SQLITE_FCNTL_WIN32_AV_RETRY = 9;

const int SQLITE_FCNTL_PERSIST_WAL = 10;

const int SQLITE_FCNTL_OVERWRITE = 11;

const int SQLITE_FCNTL_VFSNAME = 12;

const int SQLITE_FCNTL_POWERSAFE_OVERWRITE = 13;

const int SQLITE_FCNTL_PRAGMA = 14;

const int SQLITE_FCNTL_BUSYHANDLER = 15;

const int SQLITE_FCNTL_TEMPFILENAME = 16;

const int SQLITE_FCNTL_MMAP_SIZE = 18;

const int SQLITE_FCNTL_TRACE = 19;

const int SQLITE_FCNTL_HAS_MOVED = 20;

const int SQLITE_FCNTL_SYNC = 21;

const int SQLITE_FCNTL_COMMIT_PHASETWO = 22;

const int SQLITE_FCNTL_WIN32_SET_HANDLE = 23;

const int SQLITE_FCNTL_WAL_BLOCK = 24;

const int SQLITE_FCNTL_ZIPVFS = 25;

const int SQLITE_FCNTL_RBU = 26;

const int SQLITE_FCNTL_VFS_POINTER = 27;

const int SQLITE_FCNTL_JOURNAL_POINTER = 28;

const int SQLITE_FCNTL_WIN32_GET_HANDLE = 29;

const int SQLITE_FCNTL_PDB = 30;

const int SQLITE_FCNTL_BEGIN_ATOMIC_WRITE = 31;

const int SQLITE_FCNTL_COMMIT_ATOMIC_WRITE = 32;

const int SQLITE_FCNTL_ROLLBACK_ATOMIC_WRITE = 33;

const int SQLITE_FCNTL_LOCK_TIMEOUT = 34;

const int SQLITE_FCNTL_DATA_VERSION = 35;

const int SQLITE_FCNTL_SIZE_LIMIT = 36;

const int SQLITE_FCNTL_CKPT_DONE = 37;

const int SQLITE_FCNTL_RESERVE_BYTES = 38;

const int SQLITE_FCNTL_CKPT_START = 39;

const int SQLITE_GET_LOCKPROXYFILE = 2;

const int SQLITE_SET_LOCKPROXYFILE = 3;

const int SQLITE_LAST_ERRNO = 4;

const int SQLITE_ACCESS_EXISTS = 0;

const int SQLITE_ACCESS_READWRITE = 1;

const int SQLITE_ACCESS_READ = 2;

const int SQLITE_SHM_UNLOCK = 1;

const int SQLITE_SHM_LOCK = 2;

const int SQLITE_SHM_SHARED = 4;

const int SQLITE_SHM_EXCLUSIVE = 8;

const int SQLITE_SHM_NLOCK = 8;

const int SQLITE_CONFIG_SINGLETHREAD = 1;

const int SQLITE_CONFIG_MULTITHREAD = 2;

const int SQLITE_CONFIG_SERIALIZED = 3;

const int SQLITE_CONFIG_MALLOC = 4;

const int SQLITE_CONFIG_GETMALLOC = 5;

const int SQLITE_CONFIG_SCRATCH = 6;

const int SQLITE_CONFIG_PAGECACHE = 7;

const int SQLITE_CONFIG_HEAP = 8;

const int SQLITE_CONFIG_MEMSTATUS = 9;

const int SQLITE_CONFIG_MUTEX = 10;

const int SQLITE_CONFIG_GETMUTEX = 11;

const int SQLITE_CONFIG_LOOKASIDE = 13;

const int SQLITE_CONFIG_PCACHE = 14;

const int SQLITE_CONFIG_GETPCACHE = 15;

const int SQLITE_CONFIG_LOG = 16;

const int SQLITE_CONFIG_URI = 17;

const int SQLITE_CONFIG_PCACHE2 = 18;

const int SQLITE_CONFIG_GETPCACHE2 = 19;

const int SQLITE_CONFIG_COVERING_INDEX_SCAN = 20;

const int SQLITE_CONFIG_SQLLOG = 21;

const int SQLITE_CONFIG_MMAP_SIZE = 22;

const int SQLITE_CONFIG_WIN32_HEAPSIZE = 23;

const int SQLITE_CONFIG_PCACHE_HDRSZ = 24;

const int SQLITE_CONFIG_PMASZ = 25;

const int SQLITE_CONFIG_STMTJRNL_SPILL = 26;

const int SQLITE_CONFIG_SMALL_MALLOC = 27;

const int SQLITE_CONFIG_SORTERREF_SIZE = 28;

const int SQLITE_CONFIG_MEMDB_MAXSIZE = 29;

const int SQLITE_DBCONFIG_MAINDBNAME = 1000;

const int SQLITE_DBCONFIG_LOOKASIDE = 1001;

const int SQLITE_DBCONFIG_ENABLE_FKEY = 1002;

const int SQLITE_DBCONFIG_ENABLE_TRIGGER = 1003;

const int SQLITE_DBCONFIG_ENABLE_FTS3_TOKENIZER = 1004;

const int SQLITE_DBCONFIG_ENABLE_LOAD_EXTENSION = 1005;

const int SQLITE_DBCONFIG_NO_CKPT_ON_CLOSE = 1006;

const int SQLITE_DBCONFIG_ENABLE_QPSG = 1007;

const int SQLITE_DBCONFIG_TRIGGER_EQP = 1008;

const int SQLITE_DBCONFIG_RESET_DATABASE = 1009;

const int SQLITE_DBCONFIG_DEFENSIVE = 1010;

const int SQLITE_DBCONFIG_WRITABLE_SCHEMA = 1011;

const int SQLITE_DBCONFIG_LEGACY_ALTER_TABLE = 1012;

const int SQLITE_DBCONFIG_DQS_DML = 1013;

const int SQLITE_DBCONFIG_DQS_DDL = 1014;

const int SQLITE_DBCONFIG_ENABLE_VIEW = 1015;

const int SQLITE_DBCONFIG_LEGACY_FILE_FORMAT = 1016;

const int SQLITE_DBCONFIG_TRUSTED_SCHEMA = 1017;

const int SQLITE_DBCONFIG_MAX = 1017;

const int SQLITE_DENY = 1;

const int SQLITE_IGNORE = 2;

const int SQLITE_CREATE_INDEX = 1;

const int SQLITE_CREATE_TABLE = 2;

const int SQLITE_CREATE_TEMP_INDEX = 3;

const int SQLITE_CREATE_TEMP_TABLE = 4;

const int SQLITE_CREATE_TEMP_TRIGGER = 5;

const int SQLITE_CREATE_TEMP_VIEW = 6;

const int SQLITE_CREATE_TRIGGER = 7;

const int SQLITE_CREATE_VIEW = 8;

const int SQLITE_DELETE = 9;

const int SQLITE_DROP_INDEX = 10;

const int SQLITE_DROP_TABLE = 11;

const int SQLITE_DROP_TEMP_INDEX = 12;

const int SQLITE_DROP_TEMP_TABLE = 13;

const int SQLITE_DROP_TEMP_TRIGGER = 14;

const int SQLITE_DROP_TEMP_VIEW = 15;

const int SQLITE_DROP_TRIGGER = 16;

const int SQLITE_DROP_VIEW = 17;

const int SQLITE_INSERT = 18;

const int SQLITE_PRAGMA = 19;

const int SQLITE_READ = 20;

const int SQLITE_SELECT = 21;

const int SQLITE_TRANSACTION = 22;

const int SQLITE_UPDATE = 23;

const int SQLITE_ATTACH = 24;

const int SQLITE_DETACH = 25;

const int SQLITE_ALTER_TABLE = 26;

const int SQLITE_REINDEX = 27;

const int SQLITE_ANALYZE = 28;

const int SQLITE_CREATE_VTABLE = 29;

const int SQLITE_DROP_VTABLE = 30;

const int SQLITE_FUNCTION = 31;

const int SQLITE_SAVEPOINT = 32;

const int SQLITE_COPY = 0;

const int SQLITE_RECURSIVE = 33;

const int SQLITE_TRACE_STMT = 1;

const int SQLITE_TRACE_PROFILE = 2;

const int SQLITE_TRACE_ROW = 4;

const int SQLITE_TRACE_CLOSE = 8;

const int SQLITE_LIMIT_LENGTH = 0;

const int SQLITE_LIMIT_SQL_LENGTH = 1;

const int SQLITE_LIMIT_COLUMN = 2;

const int SQLITE_LIMIT_EXPR_DEPTH = 3;

const int SQLITE_LIMIT_COMPOUND_SELECT = 4;

const int SQLITE_LIMIT_VDBE_OP = 5;

const int SQLITE_LIMIT_FUNCTION_ARG = 6;

const int SQLITE_LIMIT_ATTACHED = 7;

const int SQLITE_LIMIT_LIKE_PATTERN_LENGTH = 8;

const int SQLITE_LIMIT_VARIABLE_NUMBER = 9;

const int SQLITE_LIMIT_TRIGGER_DEPTH = 10;

const int SQLITE_LIMIT_WORKER_THREADS = 11;

const int SQLITE_PREPARE_PERSISTENT = 1;

const int SQLITE_PREPARE_NORMALIZE = 2;

const int SQLITE_PREPARE_NO_VTAB = 4;

const int SQLITE_INTEGER = 1;

const int SQLITE_FLOAT = 2;

const int SQLITE_BLOB = 4;

const int SQLITE_NULL = 5;

const int SQLITE_TEXT = 3;

const int SQLITE3_TEXT = 3;

const int SQLITE_UTF8 = 1;

const int SQLITE_UTF16LE = 2;

const int SQLITE_UTF16BE = 3;

const int SQLITE_UTF16 = 4;

const int SQLITE_ANY = 5;

const int SQLITE_UTF16_ALIGNED = 8;

const int SQLITE_DETERMINISTIC = 2048;

const int SQLITE_DIRECTONLY = 524288;

const int SQLITE_SUBTYPE = 1048576;

const int SQLITE_INNOCUOUS = 2097152;

const int SQLITE_WIN32_DATA_DIRECTORY_TYPE = 1;

const int SQLITE_WIN32_TEMP_DIRECTORY_TYPE = 2;

const int SQLITE_INDEX_SCAN_UNIQUE = 1;

const int SQLITE_INDEX_CONSTRAINT_EQ = 2;

const int SQLITE_INDEX_CONSTRAINT_GT = 4;

const int SQLITE_INDEX_CONSTRAINT_LE = 8;

const int SQLITE_INDEX_CONSTRAINT_LT = 16;

const int SQLITE_INDEX_CONSTRAINT_GE = 32;

const int SQLITE_INDEX_CONSTRAINT_MATCH = 64;

const int SQLITE_INDEX_CONSTRAINT_LIKE = 65;

const int SQLITE_INDEX_CONSTRAINT_GLOB = 66;

const int SQLITE_INDEX_CONSTRAINT_REGEXP = 67;

const int SQLITE_INDEX_CONSTRAINT_NE = 68;

const int SQLITE_INDEX_CONSTRAINT_ISNOT = 69;

const int SQLITE_INDEX_CONSTRAINT_ISNOTNULL = 70;

const int SQLITE_INDEX_CONSTRAINT_ISNULL = 71;

const int SQLITE_INDEX_CONSTRAINT_IS = 72;

const int SQLITE_INDEX_CONSTRAINT_FUNCTION = 150;

const int SQLITE_MUTEX_FAST = 0;

const int SQLITE_MUTEX_RECURSIVE = 1;

const int SQLITE_MUTEX_STATIC_MASTER = 2;

const int SQLITE_MUTEX_STATIC_MEM = 3;

const int SQLITE_MUTEX_STATIC_MEM2 = 4;

const int SQLITE_MUTEX_STATIC_OPEN = 4;

const int SQLITE_MUTEX_STATIC_PRNG = 5;

const int SQLITE_MUTEX_STATIC_LRU = 6;

const int SQLITE_MUTEX_STATIC_LRU2 = 7;

const int SQLITE_MUTEX_STATIC_PMEM = 7;

const int SQLITE_MUTEX_STATIC_APP1 = 8;

const int SQLITE_MUTEX_STATIC_APP2 = 9;

const int SQLITE_MUTEX_STATIC_APP3 = 10;

const int SQLITE_MUTEX_STATIC_VFS1 = 11;

const int SQLITE_MUTEX_STATIC_VFS2 = 12;

const int SQLITE_MUTEX_STATIC_VFS3 = 13;

const int SQLITE_TESTCTRL_FIRST = 5;

const int SQLITE_TESTCTRL_PRNG_SAVE = 5;

const int SQLITE_TESTCTRL_PRNG_RESTORE = 6;

const int SQLITE_TESTCTRL_PRNG_RESET = 7;

const int SQLITE_TESTCTRL_BITVEC_TEST = 8;

const int SQLITE_TESTCTRL_FAULT_INSTALL = 9;

const int SQLITE_TESTCTRL_BENIGN_MALLOC_HOOKS = 10;

const int SQLITE_TESTCTRL_PENDING_BYTE = 11;

const int SQLITE_TESTCTRL_ASSERT = 12;

const int SQLITE_TESTCTRL_ALWAYS = 13;

const int SQLITE_TESTCTRL_RESERVE = 14;

const int SQLITE_TESTCTRL_OPTIMIZATIONS = 15;

const int SQLITE_TESTCTRL_ISKEYWORD = 16;

const int SQLITE_TESTCTRL_SCRATCHMALLOC = 17;

const int SQLITE_TESTCTRL_INTERNAL_FUNCTIONS = 17;

const int SQLITE_TESTCTRL_LOCALTIME_FAULT = 18;

const int SQLITE_TESTCTRL_EXPLAIN_STMT = 19;

const int SQLITE_TESTCTRL_ONCE_RESET_THRESHOLD = 19;

const int SQLITE_TESTCTRL_NEVER_CORRUPT = 20;

const int SQLITE_TESTCTRL_VDBE_COVERAGE = 21;

const int SQLITE_TESTCTRL_BYTEORDER = 22;

const int SQLITE_TESTCTRL_ISINIT = 23;

const int SQLITE_TESTCTRL_SORTER_MMAP = 24;

const int SQLITE_TESTCTRL_IMPOSTER = 25;

const int SQLITE_TESTCTRL_PARSER_COVERAGE = 26;

const int SQLITE_TESTCTRL_RESULT_INTREAL = 27;

const int SQLITE_TESTCTRL_PRNG_SEED = 28;

const int SQLITE_TESTCTRL_EXTRA_SCHEMA_CHECKS = 29;

const int SQLITE_TESTCTRL_LAST = 29;

const int SQLITE_STATUS_MEMORY_USED = 0;

const int SQLITE_STATUS_PAGECACHE_USED = 1;

const int SQLITE_STATUS_PAGECACHE_OVERFLOW = 2;

const int SQLITE_STATUS_SCRATCH_USED = 3;

const int SQLITE_STATUS_SCRATCH_OVERFLOW = 4;

const int SQLITE_STATUS_MALLOC_SIZE = 5;

const int SQLITE_STATUS_PARSER_STACK = 6;

const int SQLITE_STATUS_PAGECACHE_SIZE = 7;

const int SQLITE_STATUS_SCRATCH_SIZE = 8;

const int SQLITE_STATUS_MALLOC_COUNT = 9;

const int SQLITE_DBSTATUS_LOOKASIDE_USED = 0;

const int SQLITE_DBSTATUS_CACHE_USED = 1;

const int SQLITE_DBSTATUS_SCHEMA_USED = 2;

const int SQLITE_DBSTATUS_STMT_USED = 3;

const int SQLITE_DBSTATUS_LOOKASIDE_HIT = 4;

const int SQLITE_DBSTATUS_LOOKASIDE_MISS_SIZE = 5;

const int SQLITE_DBSTATUS_LOOKASIDE_MISS_FULL = 6;

const int SQLITE_DBSTATUS_CACHE_HIT = 7;

const int SQLITE_DBSTATUS_CACHE_MISS = 8;

const int SQLITE_DBSTATUS_CACHE_WRITE = 9;

const int SQLITE_DBSTATUS_DEFERRED_FKS = 10;

const int SQLITE_DBSTATUS_CACHE_USED_SHARED = 11;

const int SQLITE_DBSTATUS_CACHE_SPILL = 12;

const int SQLITE_DBSTATUS_MAX = 12;

const int SQLITE_STMTSTATUS_FULLSCAN_STEP = 1;

const int SQLITE_STMTSTATUS_SORT = 2;

const int SQLITE_STMTSTATUS_AUTOINDEX = 3;

const int SQLITE_STMTSTATUS_VM_STEP = 4;

const int SQLITE_STMTSTATUS_REPREPARE = 5;

const int SQLITE_STMTSTATUS_RUN = 6;

const int SQLITE_STMTSTATUS_MEMUSED = 99;

const int SQLITE_CHECKPOINT_PASSIVE = 0;

const int SQLITE_CHECKPOINT_FULL = 1;

const int SQLITE_CHECKPOINT_RESTART = 2;

const int SQLITE_CHECKPOINT_TRUNCATE = 3;

const int SQLITE_VTAB_CONSTRAINT_SUPPORT = 1;

const int SQLITE_VTAB_INNOCUOUS = 2;

const int SQLITE_VTAB_DIRECTONLY = 3;

const int SQLITE_ROLLBACK = 1;

const int SQLITE_FAIL = 3;

const int SQLITE_REPLACE = 5;

const int SQLITE_SCANSTAT_NLOOP = 0;

const int SQLITE_SCANSTAT_NVISIT = 1;

const int SQLITE_SCANSTAT_EST = 2;

const int SQLITE_SCANSTAT_NAME = 3;

const int SQLITE_SCANSTAT_EXPLAIN = 4;

const int SQLITE_SCANSTAT_SELECTID = 5;

const int SQLITE_SERIALIZE_NOCOPY = 1;

const int SQLITE_DESERIALIZE_FREEONCLOSE = 1;

const int SQLITE_DESERIALIZE_RESIZEABLE = 2;

const int SQLITE_DESERIALIZE_READONLY = 4;

const int NOT_WITHIN = 0;

const int PARTLY_WITHIN = 1;

const int FULLY_WITHIN = 2;

const int FTS5_TOKENIZE_QUERY = 1;

const int FTS5_TOKENIZE_PREFIX = 2;

const int FTS5_TOKENIZE_DOCUMENT = 4;

const int FTS5_TOKENIZE_AUX = 8;

const int FTS5_TOKEN_COLOCATED = 1;

typedef _c_sqlite3_close_v2 = ffi.Int32 Function(
  ffi.Pointer<sqlite3> arg0,
);

typedef _dart_sqlite3_close_v2 = int Function(
  ffi.Pointer<sqlite3> arg0,
);

typedef _c_sqlite3_open_v2 = ffi.Int32 Function(
  ffi.Pointer<ffi.Int8> filename,
  ffi.Pointer<ffi.Pointer<sqlite3>> ppDb,
  ffi.Int32 flags,
  ffi.Pointer<ffi.Int8> zVfs,
);

typedef _dart_sqlite3_open_v2 = int Function(
  ffi.Pointer<ffi.Int8> filename,
  ffi.Pointer<ffi.Pointer<sqlite3>> ppDb,
  int flags,
  ffi.Pointer<ffi.Int8> zVfs,
);

typedef _c_sqlite3_errmsg = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<sqlite3> arg0,
);

typedef _dart_sqlite3_errmsg = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<sqlite3> arg0,
);

typedef _c_sqlite3_errstr = ffi.Pointer<ffi.Int8> Function(
  ffi.Int32 arg0,
);

typedef _dart_sqlite3_errstr = ffi.Pointer<ffi.Int8> Function(
  int arg0,
);

typedef _c_sqlite3_prepare_v2 = ffi.Int32 Function(
  ffi.Pointer<sqlite3> db,
  ffi.Pointer<ffi.Int8> zSql,
  ffi.Int32 nByte,
  ffi.Pointer<ffi.Pointer<sqlite3_stmt>> ppStmt,
  ffi.Pointer<ffi.Pointer<ffi.Int8>> pzTail,
);

typedef _dart_sqlite3_prepare_v2 = int Function(
  ffi.Pointer<sqlite3> db,
  ffi.Pointer<ffi.Int8> zSql,
  int nByte,
  ffi.Pointer<ffi.Pointer<sqlite3_stmt>> ppStmt,
  ffi.Pointer<ffi.Pointer<ffi.Int8>> pzTail,
);

typedef _c_sqlite3_column_count = ffi.Int32 Function(
  ffi.Pointer<sqlite3_stmt> pStmt,
);

typedef _dart_sqlite3_column_count = int Function(
  ffi.Pointer<sqlite3_stmt> pStmt,
);

typedef _c_sqlite3_column_name = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<sqlite3_stmt> arg0,
  ffi.Int32 N,
);

typedef _dart_sqlite3_column_name = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<sqlite3_stmt> arg0,
  int N,
);

typedef _c_sqlite3_column_decltype = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<sqlite3_stmt> arg0,
  ffi.Int32 arg1,
);

typedef _dart_sqlite3_column_decltype = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<sqlite3_stmt> arg0,
  int arg1,
);

typedef _c_sqlite3_step = ffi.Int32 Function(
  ffi.Pointer<sqlite3_stmt> arg0,
);

typedef _dart_sqlite3_step = int Function(
  ffi.Pointer<sqlite3_stmt> arg0,
);

typedef _c_sqlite3_column_int = ffi.Int32 Function(
  ffi.Pointer<sqlite3_stmt> arg0,
  ffi.Int32 iCol,
);

typedef _dart_sqlite3_column_int = int Function(
  ffi.Pointer<sqlite3_stmt> arg0,
  int iCol,
);

typedef _c_sqlite3_column_text = ffi.Pointer<ffi.Uint8> Function(
  ffi.Pointer<sqlite3_stmt> arg0,
  ffi.Int32 iCol,
);

typedef _dart_sqlite3_column_text = ffi.Pointer<ffi.Uint8> Function(
  ffi.Pointer<sqlite3_stmt> arg0,
  int iCol,
);

typedef _c_sqlite3_column_type = ffi.Int32 Function(
  ffi.Pointer<sqlite3_stmt> arg0,
  ffi.Int32 iCol,
);

typedef _dart_sqlite3_column_type = int Function(
  ffi.Pointer<sqlite3_stmt> arg0,
  int iCol,
);

typedef _c_sqlite3_finalize = ffi.Int32 Function(
  ffi.Pointer<sqlite3_stmt> pStmt,
);

typedef _dart_sqlite3_finalize = int Function(
  ffi.Pointer<sqlite3_stmt> pStmt,
);

typedef _typedefC_1 = ffi.Int32 Function(
  ffi.Pointer<sqlite3_file>,
);

typedef _typedefC_2 = ffi.Int32 Function(
  ffi.Pointer<sqlite3_file>,
  ffi.Pointer<ffi.Void>,
  ffi.Int32,
  ffi.Int64,
);

typedef _typedefC_3 = ffi.Int32 Function(
  ffi.Pointer<sqlite3_file>,
  ffi.Pointer<ffi.Void>,
  ffi.Int32,
  ffi.Int64,
);

typedef _typedefC_4 = ffi.Int32 Function(
  ffi.Pointer<sqlite3_file>,
  ffi.Int64,
);

typedef _typedefC_5 = ffi.Int32 Function(
  ffi.Pointer<sqlite3_file>,
  ffi.Int32,
);

typedef _typedefC_6 = ffi.Int32 Function(
  ffi.Pointer<sqlite3_file>,
  ffi.Pointer<ffi.Int64>,
);

typedef _typedefC_7 = ffi.Int32 Function(
  ffi.Pointer<sqlite3_file>,
  ffi.Int32,
);

typedef _typedefC_8 = ffi.Int32 Function(
  ffi.Pointer<sqlite3_file>,
  ffi.Int32,
);

typedef _typedefC_9 = ffi.Int32 Function(
  ffi.Pointer<sqlite3_file>,
  ffi.Pointer<ffi.Int32>,
);

typedef _typedefC_10 = ffi.Int32 Function(
  ffi.Pointer<sqlite3_file>,
  ffi.Int32,
  ffi.Pointer<ffi.Void>,
);

typedef _typedefC_11 = ffi.Int32 Function(
  ffi.Pointer<sqlite3_file>,
);

typedef _typedefC_12 = ffi.Int32 Function(
  ffi.Pointer<sqlite3_file>,
);

typedef _typedefC_13 = ffi.Int32 Function(
  ffi.Pointer<sqlite3_file>,
  ffi.Int32,
  ffi.Int32,
  ffi.Int32,
  ffi.Pointer<ffi.Pointer<ffi.Void>>,
);

typedef _typedefC_14 = ffi.Int32 Function(
  ffi.Pointer<sqlite3_file>,
  ffi.Int32,
  ffi.Int32,
  ffi.Int32,
);

typedef _typedefC_15 = ffi.Void Function(
  ffi.Pointer<sqlite3_file>,
);

typedef _typedefC_16 = ffi.Int32 Function(
  ffi.Pointer<sqlite3_file>,
  ffi.Int32,
);

typedef _typedefC_17 = ffi.Int32 Function(
  ffi.Pointer<sqlite3_file>,
  ffi.Int64,
  ffi.Int32,
  ffi.Pointer<ffi.Pointer<ffi.Void>>,
);

typedef _typedefC_18 = ffi.Int32 Function(
  ffi.Pointer<sqlite3_file>,
  ffi.Int64,
  ffi.Pointer<ffi.Void>,
);
