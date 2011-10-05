// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DatabaseWrappingImplementation extends DOMWrapperBase implements Database {
  _DatabaseWrappingImplementation() : super() {}

  static create__DatabaseWrappingImplementation() native {
    return new _DatabaseWrappingImplementation();
  }

  String get version() { return _get__Database_version(this); }
  static String _get__Database_version(var _this) native;

  void changeVersion(String oldVersion, String newVersion, [SQLTransactionCallback callback = null, SQLTransactionErrorCallback errorCallback = null, VoidCallback successCallback = null]) {
    if (callback === null) {
      if (errorCallback === null) {
        if (successCallback === null) {
          _changeVersion(this, oldVersion, newVersion);
          return;
        }
      }
    } else {
      if (errorCallback === null) {
        if (successCallback === null) {
          _changeVersion_2(this, oldVersion, newVersion, callback);
          return;
        }
      } else {
        if (successCallback === null) {
          _changeVersion_3(this, oldVersion, newVersion, callback, errorCallback);
          return;
        } else {
          _changeVersion_4(this, oldVersion, newVersion, callback, errorCallback, successCallback);
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _changeVersion(receiver, oldVersion, newVersion) native;
  static void _changeVersion_2(receiver, oldVersion, newVersion, callback) native;
  static void _changeVersion_3(receiver, oldVersion, newVersion, callback, errorCallback) native;
  static void _changeVersion_4(receiver, oldVersion, newVersion, callback, errorCallback, successCallback) native;

  void readTransaction(SQLTransactionCallback callback, [SQLTransactionErrorCallback errorCallback = null, VoidCallback successCallback = null]) {
    if (errorCallback === null) {
      if (successCallback === null) {
        _readTransaction(this, callback);
        return;
      }
    } else {
      if (successCallback === null) {
        _readTransaction_2(this, callback, errorCallback);
        return;
      } else {
        _readTransaction_3(this, callback, errorCallback, successCallback);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _readTransaction(receiver, callback) native;
  static void _readTransaction_2(receiver, callback, errorCallback) native;
  static void _readTransaction_3(receiver, callback, errorCallback, successCallback) native;

  void transaction(SQLTransactionCallback callback, [SQLTransactionErrorCallback errorCallback = null, VoidCallback successCallback = null]) {
    if (errorCallback === null) {
      if (successCallback === null) {
        _transaction(this, callback);
        return;
      }
    } else {
      if (successCallback === null) {
        _transaction_2(this, callback, errorCallback);
        return;
      } else {
        _transaction_3(this, callback, errorCallback, successCallback);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _transaction(receiver, callback) native;
  static void _transaction_2(receiver, callback, errorCallback) native;
  static void _transaction_3(receiver, callback, errorCallback, successCallback) native;

  String get typeName() { return "Database"; }
}
