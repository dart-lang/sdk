// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGScriptElementWrappingImplementation extends _SVGElementWrappingImplementation implements SVGScriptElement {
  _SVGScriptElementWrappingImplementation() : super() {}

  static create__SVGScriptElementWrappingImplementation() native {
    return new _SVGScriptElementWrappingImplementation();
  }

  String get type() { return _get_type(this); }
  static String _get_type(var _this) native;

  void set type(String value) { _set_type(this, value); }
  static void _set_type(var _this, String value) native;

  // From SVGURIReference

  SVGAnimatedString get href() { return _get_href(this); }
  static SVGAnimatedString _get_href(var _this) native;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return _get_externalResourcesRequired(this); }
  static SVGAnimatedBoolean _get_externalResourcesRequired(var _this) native;

  String get typeName() { return "SVGScriptElement"; }
}
