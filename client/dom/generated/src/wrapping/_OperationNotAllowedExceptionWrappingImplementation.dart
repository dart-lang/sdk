// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _OperationNotAllowedExceptionWrappingImplementation extends DOMWrapperBase implements OperationNotAllowedException {
  _OperationNotAllowedExceptionWrappingImplementation() : super() {}

  static create__OperationNotAllowedExceptionWrappingImplementation() native {
    return new _OperationNotAllowedExceptionWrappingImplementation();
  }

  int get code() { return _get__OperationNotAllowedException_code(this); }
  static int _get__OperationNotAllowedException_code(var _this) native;

  String get message() { return _get__OperationNotAllowedException_message(this); }
  static String _get__OperationNotAllowedException_message(var _this) native;

  String get name() { return _get__OperationNotAllowedException_name(this); }
  static String _get__OperationNotAllowedException_name(var _this) native;

  String get typeName() { return "OperationNotAllowedException"; }
}
