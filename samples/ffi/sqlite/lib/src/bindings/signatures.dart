// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:ffi";

import "../ffi/cstring.dart";

import "types.dart";

typedef sqlite3_open_v2_native_t = Int32 Function(
    CString filename, Pointer<DatabasePointer> ppDb, Int32 flags, CString vfs);

typedef sqlite3_close_v2_native_t = Int32 Function(DatabasePointer database);

typedef sqlite3_prepare_v2_native_t = Int32 Function(
    DatabasePointer database,
    CString query,
    Int32 nbytes,
    Pointer<StatementPointer> statementOut,
    Pointer<CString> tail);

typedef sqlite3_step_native_t = Int32 Function(StatementPointer statement);

typedef sqlite3_reset_native_t = Int32 Function(StatementPointer statement);

typedef sqlite3_finalize_native_t = Int32 Function(StatementPointer statement);

typedef sqlite3_errstr_native_t = CString Function(Int32 error);

typedef sqlite3_errmsg_native_t = CString Function(DatabasePointer database);

typedef sqlite3_column_count_native_t = Int32 Function(
    StatementPointer statement);

typedef sqlite3_column_name_native_t = CString Function(
    StatementPointer statement, Int32 columnIndex);

typedef sqlite3_column_decltype_native_t = CString Function(
    StatementPointer statement, Int32 columnIndex);

typedef sqlite3_column_type_native_t = Int32 Function(
    StatementPointer statement, Int32 columnIndex);

typedef sqlite3_column_value_native_t = ValuePointer Function(
    StatementPointer statement, Int32 columnIndex);

typedef sqlite3_column_double_native_t = Double Function(
    StatementPointer statement, Int32 columnIndex);

typedef sqlite3_column_int_native_t = Int32 Function(
    StatementPointer statement, Int32 columnIndex);

typedef sqlite3_column_text_native_t = CString Function(
    StatementPointer statement, Int32 columnIndex);
