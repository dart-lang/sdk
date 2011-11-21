// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGPaintWrappingImplementation extends _SVGColorWrappingImplementation implements SVGPaint {
  _SVGPaintWrappingImplementation() : super() {}

  static create__SVGPaintWrappingImplementation() native {
    return new _SVGPaintWrappingImplementation();
  }

  int get paintType() { return _get_paintType(this); }
  static int _get_paintType(var _this) native;

  String get uri() { return _get_uri(this); }
  static String _get_uri(var _this) native;

  void setPaint(int paintType, String uri, String rgbColor, String iccColor) {
    _setPaint(this, paintType, uri, rgbColor, iccColor);
    return;
  }
  static void _setPaint(receiver, paintType, uri, rgbColor, iccColor) native;

  void setUri(String uri) {
    _setUri(this, uri);
    return;
  }
  static void _setUri(receiver, uri) native;

  String get typeName() { return "SVGPaint"; }
}
