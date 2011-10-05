// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _PositionErrorWrappingImplementation extends DOMWrapperBase implements PositionError {
  _PositionErrorWrappingImplementation() : super() {}

  static create__PositionErrorWrappingImplementation() native {
    return new _PositionErrorWrappingImplementation();
  }

  int get code() { return _get__PositionError_code(this); }
  static int _get__PositionError_code(var _this) native;

  String get message() { return _get__PositionError_message(this); }
  static String _get__PositionError_message(var _this) native;

  String get typeName() { return "PositionError"; }
}
