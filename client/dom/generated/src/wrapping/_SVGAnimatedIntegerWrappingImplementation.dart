// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGAnimatedIntegerWrappingImplementation extends DOMWrapperBase implements SVGAnimatedInteger {
  _SVGAnimatedIntegerWrappingImplementation() : super() {}

  static create__SVGAnimatedIntegerWrappingImplementation() native {
    return new _SVGAnimatedIntegerWrappingImplementation();
  }

  int get animVal() { return _get_animVal(this); }
  static int _get_animVal(var _this) native;

  int get baseVal() { return _get_baseVal(this); }
  static int _get_baseVal(var _this) native;

  void set baseVal(int value) { _set_baseVal(this, value); }
  static void _set_baseVal(var _this, int value) native;

  String get typeName() { return "SVGAnimatedInteger"; }
}
