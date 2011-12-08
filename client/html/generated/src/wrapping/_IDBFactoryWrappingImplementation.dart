// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBFactoryWrappingImplementation extends DOMWrapperBase implements IDBFactory {
  IDBFactoryWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int cmp(IDBKey first, IDBKey second) {
    return _ptr.cmp(LevelDom.unwrap(first), LevelDom.unwrap(second));
  }

  IDBVersionChangeRequest deleteDatabase(String name) {
    return LevelDom.wrapIDBVersionChangeRequest(_ptr.deleteDatabase(name));
  }

  IDBRequest getDatabaseNames() {
    return LevelDom.wrapIDBRequest(_ptr.getDatabaseNames());
  }

  IDBRequest open(String name) {
    return LevelDom.wrapIDBRequest(_ptr.open(name));
  }
}
