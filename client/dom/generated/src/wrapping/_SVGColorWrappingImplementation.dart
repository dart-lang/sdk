// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGColorWrappingImplementation extends _CSSValueWrappingImplementation implements SVGColor {
  _SVGColorWrappingImplementation() : super() {}

  static create__SVGColorWrappingImplementation() native {
    return new _SVGColorWrappingImplementation();
  }

  int get colorType() { return _get_colorType(this); }
  static int _get_colorType(var _this) native;

  RGBColor get rgbColor() { return _get_rgbColor(this); }
  static RGBColor _get_rgbColor(var _this) native;

  void setColor(int colorType, String rgbColor, String iccColor) {
    _setColor(this, colorType, rgbColor, iccColor);
    return;
  }
  static void _setColor(receiver, colorType, rgbColor, iccColor) native;

  void setRGBColor(String rgbColor) {
    _setRGBColor(this, rgbColor);
    return;
  }
  static void _setRGBColor(receiver, rgbColor) native;

  void setRGBColorICCColor(String rgbColor, String iccColor) {
    _setRGBColorICCColor(this, rgbColor, iccColor);
    return;
  }
  static void _setRGBColorICCColor(receiver, rgbColor, iccColor) native;

  String get typeName() { return "SVGColor"; }
}
