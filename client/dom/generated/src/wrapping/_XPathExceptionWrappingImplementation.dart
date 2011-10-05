// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _XPathExceptionWrappingImplementation extends DOMWrapperBase implements XPathException {
  _XPathExceptionWrappingImplementation() : super() {}

  static create__XPathExceptionWrappingImplementation() native {
    return new _XPathExceptionWrappingImplementation();
  }

  int get code() { return _get__XPathException_code(this); }
  static int _get__XPathException_code(var _this) native;

  String get message() { return _get__XPathException_message(this); }
  static String _get__XPathException_message(var _this) native;

  String get name() { return _get__XPathException_name(this); }
  static String _get__XPathException_name(var _this) native;

  String get typeName() { return "XPathException"; }
}
