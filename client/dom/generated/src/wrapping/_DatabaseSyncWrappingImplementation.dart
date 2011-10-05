// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DatabaseSyncWrappingImplementation extends DOMWrapperBase implements DatabaseSync {
  _DatabaseSyncWrappingImplementation() : super() {}

  static create__DatabaseSyncWrappingImplementation() native {
    return new _DatabaseSyncWrappingImplementation();
  }

  String get version() { return _get__DatabaseSync_version(this); }
  static String _get__DatabaseSync_version(var _this) native;

  void changeVersion(String oldVersion, String newVersion, SQLTransactionSyncCallback callback = null) {
    if (callback === null) {
      _changeVersion(this, oldVersion, newVersion);
      return;
    } else {
      _changeVersion_2(this, oldVersion, newVersion, callback);
      return;
    }
  }
  static void _changeVersion(receiver, oldVersion, newVersion) native;
  static void _changeVersion_2(receiver, oldVersion, newVersion, callback) native;

  void readTransaction(SQLTransactionSyncCallback callback) {
    _readTransaction(this, callback);
    return;
  }
  static void _readTransaction(receiver, callback) native;

  void transaction(SQLTransactionSyncCallback callback) {
    _transaction(this, callback);
    return;
  }
  static void _transaction(receiver, callback) native;

  String get typeName() { return "DatabaseSync"; }
}
