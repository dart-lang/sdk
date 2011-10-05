// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _IDBIndexWrappingImplementation extends DOMWrapperBase implements IDBIndex {
  _IDBIndexWrappingImplementation() : super() {}

  static create__IDBIndexWrappingImplementation() native {
    return new _IDBIndexWrappingImplementation();
  }

  String get keyPath() { return _get__IDBIndex_keyPath(this); }
  static String _get__IDBIndex_keyPath(var _this) native;

  String get name() { return _get__IDBIndex_name(this); }
  static String _get__IDBIndex_name(var _this) native;

  IDBObjectStore get objectStore() { return _get__IDBIndex_objectStore(this); }
  static IDBObjectStore _get__IDBIndex_objectStore(var _this) native;

  bool get unique() { return _get__IDBIndex_unique(this); }
  static bool _get__IDBIndex_unique(var _this) native;

  IDBRequest getObject(IDBKey key) {
    return _getObject(this, key);
  }
  static IDBRequest _getObject(receiver, key) native;

  IDBRequest getKey(IDBKey key) {
    return _getKey(this, key);
  }
  static IDBRequest _getKey(receiver, key) native;

  IDBRequest openCursor(IDBKeyRange range = null, int direction = null) {
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

  IDBRequest openKeyCursor(IDBKeyRange range = null, int direction = null) {
    if (range === null) {
      if (direction === null) {
        return _openKeyCursor(this);
      }
    } else {
      if (direction === null) {
        return _openKeyCursor_2(this, range);
      } else {
        return _openKeyCursor_3(this, range, direction);
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static IDBRequest _openKeyCursor(receiver) native;
  static IDBRequest _openKeyCursor_2(receiver, range) native;
  static IDBRequest _openKeyCursor_3(receiver, range, direction) native;

  String get typeName() { return "IDBIndex"; }
}
