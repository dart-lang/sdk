// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGAnimatedBooleanWrappingImplementation extends DOMWrapperBase implements SVGAnimatedBoolean {
  _SVGAnimatedBooleanWrappingImplementation() : super() {}

  static create__SVGAnimatedBooleanWrappingImplementation() native {
    return new _SVGAnimatedBooleanWrappingImplementation();
  }

  bool get animVal() { return _get_animVal(this); }
  static bool _get_animVal(var _this) native;

  bool get baseVal() { return _get_baseVal(this); }
  static bool _get_baseVal(var _this) native;

  void set baseVal(bool value) { _set_baseVal(this, value); }
  static void _set_baseVal(var _this, bool value) native;

  String get typeName() { return "SVGAnimatedBoolean"; }
}
