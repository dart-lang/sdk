// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBFactoryWrappingImplementation extends DOMWrapperBase implements IDBFactory {
  IDBFactoryWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  IDBRequest open(String name) {
    return LevelDom.wrapIDBRequest(_ptr.open(name));
  }

  String get typeName() { return "IDBFactory"; }
}
