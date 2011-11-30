// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SQLResultSetWrappingImplementation extends DOMWrapperBase implements SQLResultSet {
  _SQLResultSetWrappingImplementation() : super() {}

  static create__SQLResultSetWrappingImplementation() native {
    return new _SQLResultSetWrappingImplementation();
  }

  int get insertId() { return _get_insertId(this); }
  static int _get_insertId(var _this) native;

  SQLResultSetRowList get rows() { return _get_rows(this); }
  static SQLResultSetRowList _get_rows(var _this) native;

  int get rowsAffected() { return _get_rowsAffected(this); }
  static int _get_rowsAffected(var _this) native;

  String get typeName() { return "SQLResultSet"; }
}
