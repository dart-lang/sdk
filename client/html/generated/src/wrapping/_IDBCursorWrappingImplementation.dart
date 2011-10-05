// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBCursorWrappingImplementation extends DOMWrapperBase implements IDBCursor {
  IDBCursorWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get direction() { return _ptr.direction; }

  IDBKey get key() { return LevelDom.wrapIDBKey(_ptr.key); }

  IDBKey get primaryKey() { return LevelDom.wrapIDBKey(_ptr.primaryKey); }

  IDBAny get source() { return LevelDom.wrapIDBAny(_ptr.source); }

  IDBRequest delete() {
    return LevelDom.wrapIDBRequest(_ptr.delete());
  }

  IDBRequest update(String value) {
    return LevelDom.wrapIDBRequest(_ptr.update(value));
  }

  String get typeName() { return "IDBCursor"; }
}
