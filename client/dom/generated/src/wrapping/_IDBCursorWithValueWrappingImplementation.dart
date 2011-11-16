// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _IDBCursorWithValueWrappingImplementation extends _IDBCursorWrappingImplementation implements IDBCursorWithValue {
  _IDBCursorWithValueWrappingImplementation() : super() {}

  static create__IDBCursorWithValueWrappingImplementation() native {
    return new _IDBCursorWithValueWrappingImplementation();
  }

  IDBAny get value() { return _get__IDBCursorWithValue_value(this); }
  static IDBAny _get__IDBCursorWithValue_value(var _this) native;

  String get typeName() { return "IDBCursorWithValue"; }
}
