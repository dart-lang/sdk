// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGAltGlyphElementWrappingImplementation extends _SVGTextPositioningElementWrappingImplementation implements SVGAltGlyphElement {
  _SVGAltGlyphElementWrappingImplementation() : super() {}

  static create__SVGAltGlyphElementWrappingImplementation() native {
    return new _SVGAltGlyphElementWrappingImplementation();
  }

  String get format() { return _get_format(this); }
  static String _get_format(var _this) native;

  void set format(String value) { _set_format(this, value); }
  static void _set_format(var _this, String value) native;

  String get glyphRef() { return _get_glyphRef(this); }
  static String _get_glyphRef(var _this) native;

  void set glyphRef(String value) { _set_glyphRef(this, value); }
  static void _set_glyphRef(var _this, String value) native;

  // From SVGURIReference

  SVGAnimatedString get href() { return _get_href(this); }
  static SVGAnimatedString _get_href(var _this) native;

  String get typeName() { return "SVGAltGlyphElement"; }
}
