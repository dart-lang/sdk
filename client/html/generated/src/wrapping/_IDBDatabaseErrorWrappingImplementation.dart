// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBDatabaseErrorWrappingImplementation extends DOMWrapperBase implements IDBDatabaseError {
  IDBDatabaseErrorWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get code() { return _ptr.code; }

  void set code(int value) { _ptr.code = value; }

  String get message() { return _ptr.message; }

  void set message(String value) { _ptr.message = value; }

  String get typeName() { return "IDBDatabaseError"; }
}
