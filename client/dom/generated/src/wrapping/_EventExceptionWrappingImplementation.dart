// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _EventExceptionWrappingImplementation extends DOMWrapperBase implements EventException {
  _EventExceptionWrappingImplementation() : super() {}

  static create__EventExceptionWrappingImplementation() native {
    return new _EventExceptionWrappingImplementation();
  }

  int get code() { return _get__EventException_code(this); }
  static int _get__EventException_code(var _this) native;

  String get message() { return _get__EventException_message(this); }
  static String _get__EventException_message(var _this) native;

  String get name() { return _get__EventException_name(this); }
  static String _get__EventException_name(var _this) native;

  String get typeName() { return "EventException"; }
}
