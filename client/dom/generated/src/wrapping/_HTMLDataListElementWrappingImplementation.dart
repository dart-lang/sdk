// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLDataListElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLDataListElement {
  _HTMLDataListElementWrappingImplementation() : super() {}

  static create__HTMLDataListElementWrappingImplementation() native {
    return new _HTMLDataListElementWrappingImplementation();
  }

  HTMLCollection get options() { return _get_options(this); }
  static HTMLCollection _get_options(var _this) native;

  String get typeName() { return "HTMLDataListElement"; }
}
