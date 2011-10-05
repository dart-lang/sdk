// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLTitleElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLTitleElement {
  _HTMLTitleElementWrappingImplementation() : super() {}

  static create__HTMLTitleElementWrappingImplementation() native {
    return new _HTMLTitleElementWrappingImplementation();
  }

  String get text() { return _get__HTMLTitleElement_text(this); }
  static String _get__HTMLTitleElement_text(var _this) native;

  void set text(String value) { _set__HTMLTitleElement_text(this, value); }
  static void _set__HTMLTitleElement_text(var _this, String value) native;

  String get typeName() { return "HTMLTitleElement"; }
}
