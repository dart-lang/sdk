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

  IDBRequest getKey(IDBKey key) {
    return LevelDom.wrapIDBRequest(_ptr.getKey(LevelDom.unwrap(key)));
  }

  IDBRequest openCursor(IDBKeyRange range, int direction) {
    return LevelDom.wrapIDBRequest(_ptr.openCursor(LevelDom.unwrap(range), direction));
  }

  IDBRequest openKeyCursor(IDBKeyRange range, int direction) {
    return LevelDom.wrapIDBRequest(_ptr.openKeyCursor(LevelDom.unwrap(range), direction));
  }

  String get typeName() { return "IDBIndex"; }
}
