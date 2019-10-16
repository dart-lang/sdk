// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:ffi";

/// Database Connection Handle
///
/// Each open SQLite database is represented by a pointer to an instance of
/// the opaque structure named "sqlite3".  It is useful to think of an sqlite3
/// pointer as an object.  The [sqlite3_open()], [sqlite3_open16()], and
/// [sqlite3_open_v2()] interfaces are its constructors, and [sqlite3_close()]
/// is its destructor.  There are many other interfaces (such as
/// [sqlite3_prepare_v2()], [sqlite3_create_function()], and
/// [sqlite3_busy_timeout()] to name but three) that are methods on an
class Database extends Struct {}

/// SQL Statement Object
///
/// An instance of this object represents a single SQL statement.
/// This object is variously known as a "prepared statement" or a
/// "compiled SQL statement" or simply as a "statement".
///
/// The life of a statement object goes something like this:
///
/// <ol>
/// <li> Create the object using [sqlite3_prepare_v2()] or a related
///      function.
/// <li> Bind values to [host parameters] using the sqlite3_bind_*()
///      interfaces.
/// <li> Run the SQL by calling [sqlite3_step()] one or more times.
/// <li> Reset the statement using [sqlite3_reset()] then go back
///      to step 2.  Do this zero or more times.
/// <li> Destroy the object using [sqlite3_finalize()].
/// </ol>
///
/// Refer to documentation on individual methods above for additional
/// information.
class Statement extends Struct {}

/// Dynamically Typed Value Object
///
/// SQLite uses the sqlite3_value object to represent all values
/// that can be stored in a database table. SQLite uses dynamic typing
/// for the values it stores.  ^Values stored in sqlite3_value objects
/// can be integers, floating point values, strings, BLOBs, or NULL.
///
/// An sqlite3_value object may be either "protected" or "unprotected".
/// Some interfaces require a protected sqlite3_value.  Other interfaces
/// will accept either a protected or an unprotected sqlite3_value.
/// Every interface that accepts sqlite3_value arguments specifies
/// whether or not it requires a protected sqlite3_value.
///
/// The terms "protected" and "unprotected" refer to whether or not
/// a mutex is held.  An internal mutex is held for a protected
/// sqlite3_value object but no mutex is held for an unprotected
/// sqlite3_value object.  If SQLite is compiled to be single-threaded
/// (with [SQLITE_THREADSAFE=0] and with [sqlite3_threadsafe()] returning 0)
/// or if SQLite is run in one of reduced mutex modes
/// [SQLITE_CONFIG_SINGLETHREAD] or [SQLITE_CONFIG_MULTITHREAD]
/// then there is no distinction between protected and unprotected
/// sqlite3_value objects and they can be used interchangeably.  However,
/// for maximum code portability it is recommended that applications
/// still make the distinction between protected and unprotected
/// sqlite3_value objects even when not strictly required.
///
/// ^The sqlite3_value objects that are passed as parameters into the
/// implementation of [application-defined SQL functions] are protected.
/// ^The sqlite3_value object returned by
/// [sqlite3_column_value()] is unprotected.
/// Unprotected sqlite3_value objects may only be used with
/// [sqlite3_result_value()] and [sqlite3_bind_value()].
/// The [sqlite3_value_blob | sqlite3_value_type()] family of
/// interfaces require protected sqlite3_value objects.
class Value extends Struct {}
