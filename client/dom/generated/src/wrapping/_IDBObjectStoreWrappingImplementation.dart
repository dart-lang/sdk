// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _IDBObjectStoreWrappingImplementation extends DOMWrapperBase implements IDBObjectStore {
  _IDBObjectStoreWrappingImplementation() : super() {}

  static create__IDBObjectStoreWrappingImplementation() native {
    return new _IDBObjectStoreWrappingImplementation();
  }

  String get keyPath() { return _get__IDBObjectStore_keyPath(this); }
  static String _get__IDBObjectStore_keyPath(var _this) native;

  String get name() { return _get__IDBObjectStore_name(this); }
  static String _get__IDBObjectStore_name(var _this) native;

  IDBTransaction get transaction() { return _get__IDBObjectStore_transaction(this); }
  static IDBTransaction _get__IDBObjectStore_transaction(var _this) native;

  IDBRequest add(String value, [IDBKey key = null]) {
    if (key === null) {
      return _add(this, value);
    } else {
      return _add_2(this, value, key);
    }
  }
  static IDBRequest _add(receiver, value) native;
  static IDBRequest _add_2(receiver, value, key) native;

  IDBRequest clear() {
    return _clear(this);
  }
  static IDBRequest _clear(receiver) native;

  IDBIndex createIndex(String name, String keyPath) {
    return _createIndex(this, name, keyPath);
  }
  static IDBIndex _createIndex(receiver, name, keyPath) native;

  IDBRequest delete(IDBKey key) {
    return _delete(this, key);
  }
  static IDBRequest _delete(receiver, key) native;

  void deleteIndex(String name) {
    _deleteIndex(this, name);
    return;
  }
  static void _deleteIndex(receiver, name) native;

  IDBRequest getObject(IDBKey key) {
    return _getObject(this, key);
  }
  static IDBRequest _getObject(receiver, key) native;

  IDBIndex index(String name) {
    return _index(this, name);
  }
  static IDBIndex _index(receiver, name) native;

  IDBRequest openCursor([IDBKeyRange range = null, int direction = null]) {
    if (range === null) {
      if (direction === null) {
        return _openCursor(this);
      }
    } else {
      if (direction === null) {
        return _openCursor_2(this, range);
      } else {
        return _openCursor_3(this, range, direction);
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static IDBRequest _openCursor(receiver) native;
  static IDBRequest _openCursor_2(receiver, range) native;
  static IDBRequest _openCursor_3(receiver, range, direction) native;

  IDBRequest put(String value, [IDBKey key = null]) {
    if (key === null) {
      return _put(this, value);
    } else {
      return _put_2(this, value, key);
    }
  }
  static IDBRequest _put(receiver, value) native;
  static IDBRequest _put_2(receiver, value, key) native;

  String get typeName() { return "IDBObjectStore"; }
}
