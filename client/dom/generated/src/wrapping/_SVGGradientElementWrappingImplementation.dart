// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGGradientElementWrappingImplementation extends _SVGElementWrappingImplementation implements SVGGradientElement {
  _SVGGradientElementWrappingImplementation() : super() {}

  static create__SVGGradientElementWrappingImplementation() native {
    return new _SVGGradientElementWrappingImplementation();
  }

  SVGAnimatedTransformList get gradientTransform() { return _get_gradientTransform(this); }
  static SVGAnimatedTransformList _get_gradientTransform(var _this) native;

  SVGAnimatedEnumeration get gradientUnits() { return _get_gradientUnits(this); }
  static SVGAnimatedEnumeration _get_gradientUnits(var _this) native;

  SVGAnimatedEnumeration get spreadMethod() { return _get_spreadMethod(this); }
  static SVGAnimatedEnumeration _get_spreadMethod(var _this) native;

  // From SVGURIReference

  SVGAnimatedString get href() { return _get_href(this); }
  static SVGAnimatedString _get_href(var _this) native;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return _get_externalResourcesRequired(this); }
  static SVGAnimatedBoolean _get_externalResourcesRequired(var _this) native;

  // From SVGStylable

  SVGAnimatedString get className() { return _get_className(this); }
  static SVGAnimatedString _get_className(var _this) native;

  CSSStyleDeclaration get style() { return _get_style_SVGGradientElement(this); }
  static CSSStyleDeclaration _get_style_SVGGradientElement(var _this) native;

  CSSValue getPresentationAttribute(String name) {
    return _getPresentationAttribute(this, name);
  }
  static CSSValue _getPresentationAttribute(receiver, name) native;

  String get typeName() { return "SVGGradientElement"; }
}
