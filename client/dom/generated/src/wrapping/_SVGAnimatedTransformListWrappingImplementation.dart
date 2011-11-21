// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGAnimatedTransformListWrappingImplementation extends DOMWrapperBase implements SVGAnimatedTransformList {
  _SVGAnimatedTransformListWrappingImplementation() : super() {}

  static create__SVGAnimatedTransformListWrappingImplementation() native {
    return new _SVGAnimatedTransformListWrappingImplementation();
  }

  SVGTransformList get animVal() { return _get_animVal(this); }
  static SVGTransformList _get_animVal(var _this) native;

  SVGTransformList get baseVal() { return _get_baseVal(this); }
  static SVGTransformList _get_baseVal(var _this) native;

  String get typeName() { return "SVGAnimatedTransformList"; }
}
