// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SQLExceptionWrappingImplementation extends DOMWrapperBase implements SQLException {
  _SQLExceptionWrappingImplementation() : super() {}

  static create__SQLExceptionWrappingImplementation() native {
    return new _SQLExceptionWrappingImplementation();
  }

  int get code() { return _get__SQLException_code(this); }
  static int _get__SQLException_code(var _this) native;

  String get message() { return _get__SQLException_message(this); }
  static String _get__SQLException_message(var _this) native;

  String get typeName() { return "SQLException"; }
}
