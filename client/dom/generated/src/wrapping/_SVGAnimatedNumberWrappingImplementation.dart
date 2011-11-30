// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGAnimatedNumberWrappingImplementation extends DOMWrapperBase implements SVGAnimatedNumber {
  _SVGAnimatedNumberWrappingImplementation() : super() {}

  static create__SVGAnimatedNumberWrappingImplementation() native {
    return new _SVGAnimatedNumberWrappingImplementation();
  }

  num get animVal() { return _get_animVal(this); }
  static num _get_animVal(var _this) native;

  num get baseVal() { return _get_baseVal(this); }
  static num _get_baseVal(var _this) native;

  void set baseVal(num value) { _set_baseVal(this, value); }
  static void _set_baseVal(var _this, num value) native;

  String get typeName() { return "SVGAnimatedNumber"; }
}
