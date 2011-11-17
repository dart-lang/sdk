// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _XMLHttpRequestExceptionWrappingImplementation extends DOMWrapperBase implements XMLHttpRequestException {
  _XMLHttpRequestExceptionWrappingImplementation() : super() {}

  static create__XMLHttpRequestExceptionWrappingImplementation() native {
    return new _XMLHttpRequestExceptionWrappingImplementation();
  }

  int get code() { return _get__XMLHttpRequestException_code(this); }
  static int _get__XMLHttpRequestException_code(var _this) native;

  String get message() { return _get__XMLHttpRequestException_message(this); }
  static String _get__XMLHttpRequestException_message(var _this) native;

  String get name() { return _get__XMLHttpRequestException_name(this); }
  static String _get__XMLHttpRequestException_name(var _this) native;

  String toString() {
    return _toString(this);
  }
  static String _toString(receiver) native;

  String get typeName() { return "XMLHttpRequestException"; }
}
