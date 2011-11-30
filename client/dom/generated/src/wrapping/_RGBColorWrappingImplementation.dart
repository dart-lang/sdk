// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _RGBColorWrappingImplementation extends DOMWrapperBase implements RGBColor {
  _RGBColorWrappingImplementation() : super() {}

  static create__RGBColorWrappingImplementation() native {
    return new _RGBColorWrappingImplementation();
  }

  CSSPrimitiveValue get blue() { return _get_blue(this); }
  static CSSPrimitiveValue _get_blue(var _this) native;

  CSSPrimitiveValue get green() { return _get_green(this); }
  static CSSPrimitiveValue _get_green(var _this) native;

  CSSPrimitiveValue get red() { return _get_red(this); }
  static CSSPrimitiveValue _get_red(var _this) native;

  String get typeName() { return "RGBColor"; }
}
