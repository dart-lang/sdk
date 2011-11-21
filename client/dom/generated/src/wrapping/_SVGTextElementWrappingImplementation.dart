// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGTextElementWrappingImplementation extends _SVGTextPositioningElementWrappingImplementation implements SVGTextElement {
  _SVGTextElementWrappingImplementation() : super() {}

  static create__SVGTextElementWrappingImplementation() native {
    return new _SVGTextElementWrappingImplementation();
  }

  // From SVGTransformable

  SVGAnimatedTransformList get transform() { return _get_transform(this); }
  static SVGAnimatedTransformList _get_transform(var _this) native;

  // From SVGLocatable

  SVGElement get farthestViewportElement() { return _get_farthestViewportElement(this); }
  static SVGElement _get_farthestViewportElement(var _this) native;

  SVGElement get nearestViewportElement() { return _get_nearestViewportElement(this); }
  static SVGElement _get_nearestViewportElement(var _this) native;

  SVGRect getBBox() {
    return _getBBox(this);
  }
  static SVGRect _getBBox(receiver) native;

  SVGMatrix getCTM() {
    return _getCTM(this);
  }
  static SVGMatrix _getCTM(receiver) native;

  SVGMatrix getScreenCTM() {
    return _getScreenCTM(this);
  }
  static SVGMatrix _getScreenCTM(receiver) native;

  SVGMatrix getTransformToElement(SVGElement element) {
    return _getTransformToElement(this, element);
  }
  static SVGMatrix _getTransformToElement(receiver, element) native;

  String get typeName() { return "SVGTextElement"; }
}
