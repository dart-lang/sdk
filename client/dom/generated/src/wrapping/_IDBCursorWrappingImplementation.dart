// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _IDBCursorWrappingImplementation extends DOMWrapperBase implements IDBCursor {
  _IDBCursorWrappingImplementation() : super() {}

  static create__IDBCursorWrappingImplementation() native {
    return new _IDBCursorWrappingImplementation();
  }

  int get direction() { return _get_direction(this); }
  static int _get_direction(var _this) native;

  IDBKey get key() { return _get_key(this); }
  static IDBKey _get_key(var _this) native;

  IDBKey get primaryKey() { return _get_primaryKey(this); }
  static IDBKey _get_primaryKey(var _this) native;

  IDBAny get source() { return _get_source(this); }
  static IDBAny _get_source(var _this) native;

  void continueFunction([IDBKey key = null]) {
    if (key === null) {
      _continueFunction(this);
      return;
    } else {
      _continueFunction_2(this, key);
      return;
    }
  }
  static void _continueFunction(receiver) native;
  static void _continueFunction_2(receiver, key) native;

  IDBRequest delete() {
    return _delete(this);
  }
  static IDBRequest _delete(receiver) native;

  IDBRequest update(String value) {
    return _update(this, value);
  }
  static IDBRequest _update(receiver, value) native;

  String get typeName() { return "IDBCursor"; }
}
