// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGFEConvolveMatrixElementWrappingImplementation extends _SVGElementWrappingImplementation implements SVGFEConvolveMatrixElement {
  _SVGFEConvolveMatrixElementWrappingImplementation() : super() {}

  static create__SVGFEConvolveMatrixElementWrappingImplementation() native {
    return new _SVGFEConvolveMatrixElementWrappingImplementation();
  }

  SVGAnimatedNumber get bias() { return _get_bias(this); }
  static SVGAnimatedNumber _get_bias(var _this) native;

  SVGAnimatedNumber get divisor() { return _get_divisor(this); }
  static SVGAnimatedNumber _get_divisor(var _this) native;

  SVGAnimatedEnumeration get edgeMode() { return _get_edgeMode(this); }
  static SVGAnimatedEnumeration _get_edgeMode(var _this) native;

  SVGAnimatedString get in1() { return _get_in1(this); }
  static SVGAnimatedString _get_in1(var _this) native;

  SVGAnimatedNumberList get kernelMatrix() { return _get_kernelMatrix(this); }
  static SVGAnimatedNumberList _get_kernelMatrix(var _this) native;

  SVGAnimatedNumber get kernelUnitLengthX() { return _get_kernelUnitLengthX(this); }
  static SVGAnimatedNumber _get_kernelUnitLengthX(var _this) native;

  SVGAnimatedNumber get kernelUnitLengthY() { return _get_kernelUnitLengthY(this); }
  static SVGAnimatedNumber _get_kernelUnitLengthY(var _this) native;

  SVGAnimatedInteger get orderX() { return _get_orderX(this); }
  static SVGAnimatedInteger _get_orderX(var _this) native;

  SVGAnimatedInteger get orderY() { return _get_orderY(this); }
  static SVGAnimatedInteger _get_orderY(var _this) native;

  SVGAnimatedBoolean get preserveAlpha() { return _get_preserveAlpha(this); }
  static SVGAnimatedBoolean _get_preserveAlpha(var _this) native;

  SVGAnimatedInteger get targetX() { return _get_targetX(this); }
  static SVGAnimatedInteger _get_targetX(var _this) native;

  SVGAnimatedInteger get targetY() { return _get_targetY(this); }
  static SVGAnimatedInteger _get_targetY(var _this) native;

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() { return _get_height(this); }
  static SVGAnimatedLength _get_height(var _this) native;

  SVGAnimatedString get result() { return _get_result(this); }
  static SVGAnimatedString _get_result(var _this) native;

  SVGAnimatedLength get width() { return _get_width(this); }
  static SVGAnimatedLength _get_width(var _this) native;

  SVGAnimatedLength get x() { return _get_x(this); }
  static SVGAnimatedLength _get_x(var _this) native;

  SVGAnimatedLength get y() { return _get_y(this); }
  static SVGAnimatedLength _get_y(var _this) native;

  // From SVGStylable

  SVGAnimatedString get className() { return _get_className(this); }
  static SVGAnimatedString _get_className(var _this) native;

  CSSStyleDeclaration get style() { return _get_style_SVGFEConvolveMatrixElement(this); }
  static CSSStyleDeclaration _get_style_SVGFEConvolveMatrixElement(var _this) native;

  CSSValue getPresentationAttribute(String name) {
    return _getPresentationAttribute(this, name);
  }
  static CSSValue _getPresentationAttribute(receiver, name) native;

  String get typeName() { return "SVGFEConvolveMatrixElement"; }
}
