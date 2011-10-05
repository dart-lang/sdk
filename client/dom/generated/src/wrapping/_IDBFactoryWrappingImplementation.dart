// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _IDBFactoryWrappingImplementation extends DOMWrapperBase implements IDBFactory {
  _IDBFactoryWrappingImplementation() : super() {}

  static create__IDBFactoryWrappingImplementation() native {
    return new _IDBFactoryWrappingImplementation();
  }

  IDBRequest getDatabaseNames() {
    return _getDatabaseNames(this);
  }
  static IDBRequest _getDatabaseNames(receiver) native;

  IDBRequest open(String name) {
    return _open(this, name);
  }
  static IDBRequest _open(receiver, name) native;

  String get typeName() { return "IDBFactory"; }
}
