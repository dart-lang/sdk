// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _IDBVersionChangeEventWrappingImplementation extends _EventWrappingImplementation implements IDBVersionChangeEvent {
  _IDBVersionChangeEventWrappingImplementation() : super() {}

  static create__IDBVersionChangeEventWrappingImplementation() native {
    return new _IDBVersionChangeEventWrappingImplementation();
  }

  String get version() { return _get__IDBVersionChangeEvent_version(this); }
  static String _get__IDBVersionChangeEvent_version(var _this) native;

  String get typeName() { return "IDBVersionChangeEvent"; }
}
