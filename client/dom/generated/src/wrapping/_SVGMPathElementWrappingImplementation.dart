// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGMPathElementWrappingImplementation extends _SVGElementWrappingImplementation implements SVGMPathElement {
  _SVGMPathElementWrappingImplementation() : super() {}

  static create__SVGMPathElementWrappingImplementation() native {
    return new _SVGMPathElementWrappingImplementation();
  }

  // From SVGURIReference

  SVGAnimatedString get href() { return _get_href(this); }
  static SVGAnimatedString _get_href(var _this) native;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return _get_externalResourcesRequired(this); }
  static SVGAnimatedBoolean _get_externalResourcesRequired(var _this) native;

  String get typeName() { return "SVGMPathElement"; }
}
