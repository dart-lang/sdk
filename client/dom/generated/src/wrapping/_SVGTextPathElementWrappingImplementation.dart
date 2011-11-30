// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGTextPathElementWrappingImplementation extends _SVGTextContentElementWrappingImplementation implements SVGTextPathElement {
  _SVGTextPathElementWrappingImplementation() : super() {}

  static create__SVGTextPathElementWrappingImplementation() native {
    return new _SVGTextPathElementWrappingImplementation();
  }

  SVGAnimatedEnumeration get method() { return _get_method(this); }
  static SVGAnimatedEnumeration _get_method(var _this) native;

  SVGAnimatedEnumeration get spacing() { return _get_spacing(this); }
  static SVGAnimatedEnumeration _get_spacing(var _this) native;

  SVGAnimatedLength get startOffset() { return _get_startOffset(this); }
  static SVGAnimatedLength _get_startOffset(var _this) native;

  // From SVGURIReference

  SVGAnimatedString get href() { return _get_href(this); }
  static SVGAnimatedString _get_href(var _this) native;

  String get typeName() { return "SVGTextPathElement"; }
}
