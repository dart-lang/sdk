// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _IDBDatabaseExceptionWrappingImplementation extends DOMWrapperBase implements IDBDatabaseException {
  _IDBDatabaseExceptionWrappingImplementation() : super() {}

  static create__IDBDatabaseExceptionWrappingImplementation() native {
    return new _IDBDatabaseExceptionWrappingImplementation();
  }

  int get code() { return _get__IDBDatabaseException_code(this); }
  static int _get__IDBDatabaseException_code(var _this) native;

  String get message() { return _get__IDBDatabaseException_message(this); }
  static String _get__IDBDatabaseException_message(var _this) native;

  String get name() { return _get__IDBDatabaseException_name(this); }
  static String _get__IDBDatabaseException_name(var _this) native;

  String toString() {
    return _toString(this);
  }
  static String _toString(receiver) native;

  String get typeName() { return "IDBDatabaseException"; }
}
