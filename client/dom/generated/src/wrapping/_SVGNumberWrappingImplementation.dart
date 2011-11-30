// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGNumberWrappingImplementation extends DOMWrapperBase implements SVGNumber {
  _SVGNumberWrappingImplementation() : super() {}

  static create__SVGNumberWrappingImplementation() native {
    return new _SVGNumberWrappingImplementation();
  }

  num get value() { return _get_value(this); }
  static num _get_value(var _this) native;

  void set value(num value) { _set_value(this, value); }
  static void _set_value(var _this, num value) native;

  String get typeName() { return "SVGNumber"; }
}
