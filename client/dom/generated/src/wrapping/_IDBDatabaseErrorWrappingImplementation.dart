// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _IDBDatabaseErrorWrappingImplementation extends DOMWrapperBase implements IDBDatabaseError {
  _IDBDatabaseErrorWrappingImplementation() : super() {}

  static create__IDBDatabaseErrorWrappingImplementation() native {
    return new _IDBDatabaseErrorWrappingImplementation();
  }

  int get code() { return _get__IDBDatabaseError_code(this); }
  static int _get__IDBDatabaseError_code(var _this) native;

  void set code(int value) { _set__IDBDatabaseError_code(this, value); }
  static void _set__IDBDatabaseError_code(var _this, int value) native;

  String get message() { return _get__IDBDatabaseError_message(this); }
  static String _get__IDBDatabaseError_message(var _this) native;

  void set message(String value) { _set__IDBDatabaseError_message(this, value); }
  static void _set__IDBDatabaseError_message(var _this, String value) native;

  String get typeName() { return "IDBDatabaseError"; }
}
