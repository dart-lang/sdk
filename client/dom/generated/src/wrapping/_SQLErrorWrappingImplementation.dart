// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SQLErrorWrappingImplementation extends DOMWrapperBase implements SQLError {
  _SQLErrorWrappingImplementation() : super() {}

  static create__SQLErrorWrappingImplementation() native {
    return new _SQLErrorWrappingImplementation();
  }

  int get code() { return _get__SQLError_code(this); }
  static int _get__SQLError_code(var _this) native;

  String get message() { return _get__SQLError_message(this); }
  static String _get__SQLError_message(var _this) native;

  String get typeName() { return "SQLError"; }
}
