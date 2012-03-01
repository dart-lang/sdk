// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DatabaseWrappingImplementation extends DOMWrapperBase implements Database {
  _DatabaseWrappingImplementation() : super() {}

  static create__DatabaseWrappingImplementation() native {
    return new _DatabaseWrappingImplementation();
  }

  String get version() { return _get_version(this); }
  static String _get_version(var _this) native;

  void changeVersion(String oldVersion, String newVersion, [SQLTransactionCallback callback = null, SQLTransactionErrorCallback errorCallback = null, VoidCallback successCallback = null]) {
    _changeVersion(this, oldVersion, newVersion, callback, errorCallback, successCallback);
    return;
  }
  static void _changeVersion(receiver, oldVersion, newVersion, callback, errorCallback, successCallback) native;

  void readTransaction(SQLTransactionCallback callback, [SQLTransactionErrorCallback errorCallback = null, VoidCallback successCallback = null]) {
    _readTransaction(this, callback, errorCallback, successCallback);
    return;
  }
  static void _readTransaction(receiver, callback, errorCallback, successCallback) native;

  void transaction(SQLTransactionCallback callback, [SQLTransactionErrorCallback errorCallback = null, VoidCallback successCallback = null]) {
    _transaction(this, callback, errorCallback, successCallback);
    return;
  }
  static void _transaction(receiver, callback, errorCallback, successCallback) native;

  String get typeName() { return "Database"; }
}
