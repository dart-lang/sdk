// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGElementWrappingImplementation extends _ElementWrappingImplementation implements SVGElement {
  _SVGElementWrappingImplementation() : super() {}

  static create__SVGElementWrappingImplementation() native {
    return new _SVGElementWrappingImplementation();
  }

  String get id() { return _get_id(this); }
  static String _get_id(var _this) native;

  void set id(String value) { _set_id(this, value); }
  static void _set_id(var _this, String value) native;

  SVGSVGElement get ownerSVGElement() { return _get_ownerSVGElement(this); }
  static SVGSVGElement _get_ownerSVGElement(var _this) native;

  SVGElement get viewportElement() { return _get_viewportElement(this); }
  static SVGElement _get_viewportElement(var _this) native;

  String get xmlbase() { return _get_xmlbase(this); }
  static String _get_xmlbase(var _this) native;

  void set xmlbase(String value) { _set_xmlbase(this, value); }
  static void _set_xmlbase(var _this, String value) native;

  String get typeName() { return "SVGElement"; }
}
