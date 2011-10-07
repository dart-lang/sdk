// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBIndexWrappingImplementation extends DOMWrapperBase implements IDBIndex {
  IDBIndexWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get keyPath() { return _ptr.keyPath; }

  String get name() { return _ptr.name; }

  IDBObjectStore get objectStore() { return LevelDom.wrapIDBObjectStore(_ptr.objectStore); }

  bool get unique() { return _ptr.unique; }

  IDBRequest getObject(IDBKey key) {
    return LevelDom.wrapIDBRequest(_ptr.getObject(LevelDom.unwrap(key)));
  }

  IDBRequest getKey(IDBKey key) {
    return LevelDom.wrapIDBRequest(_ptr.getKey(LevelDom.unwrap(key)));
  }

  IDBRequest openCursor([IDBKeyRange range = null, int direction = null]) {
    if (range === null) {
      if (direction === null) {
        return LevelDom.wrapIDBRequest(_ptr.openCursor());
      }
    } else {
      if (direction === null) {
        return LevelDom.wrapIDBRequest(_ptr.openCursor(LevelDom.unwrap(range)));
      } else {
        return LevelDom.wrapIDBRequest(_ptr.openCursor(LevelDom.unwrap(range), direction));
      }
    }
    throw "Incorrect number or type of arguments";
  }

  IDBRequest openKeyCursor([IDBKeyRange range = null, int direction = null]) {
    if (range === null) {
      if (direction === null) {
        return LevelDom.wrapIDBRequest(_ptr.openKeyCursor());
      }
    } else {
      if (direction === null) {
        return LevelDom.wrapIDBRequest(_ptr.openKeyCursor(LevelDom.unwrap(range)));
      } else {
        return LevelDom.wrapIDBRequest(_ptr.openKeyCursor(LevelDom.unwrap(range), direction));
      }
    }
    throw "Incorrect number or type of arguments";
  }
}
