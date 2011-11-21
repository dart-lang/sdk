// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGMarkerElementWrappingImplementation extends _SVGElementWrappingImplementation implements SVGMarkerElement {
  _SVGMarkerElementWrappingImplementation() : super() {}

  static create__SVGMarkerElementWrappingImplementation() native {
    return new _SVGMarkerElementWrappingImplementation();
  }

  SVGAnimatedLength get markerHeight() { return _get_markerHeight(this); }
  static SVGAnimatedLength _get_markerHeight(var _this) native;

  SVGAnimatedEnumeration get markerUnits() { return _get_markerUnits(this); }
  static SVGAnimatedEnumeration _get_markerUnits(var _this) native;

  SVGAnimatedLength get markerWidth() { return _get_markerWidth(this); }
  static SVGAnimatedLength _get_markerWidth(var _this) native;

  SVGAnimatedAngle get orientAngle() { return _get_orientAngle(this); }
  static SVGAnimatedAngle _get_orientAngle(var _this) native;

  SVGAnimatedEnumeration get orientType() { return _get_orientType(this); }
  static SVGAnimatedEnumeration _get_orientType(var _this) native;

  SVGAnimatedLength get refX() { return _get_refX(this); }
  static SVGAnimatedLength _get_refX(var _this) native;

  SVGAnimatedLength get refY() { return _get_refY(this); }
  static SVGAnimatedLength _get_refY(var _this) native;

  void setOrientToAngle(SVGAngle angle) {
    _setOrientToAngle(this, angle);
    return;
  }
  static void _setOrientToAngle(receiver, angle) native;

  void setOrientToAuto() {
    _setOrientToAuto(this);
    return;
  }
  static void _setOrientToAuto(receiver) native;

  // From SVGLangSpace

  String get xmllang() { return _get_xmllang(this); }
  static String _get_xmllang(var _this) native;

  void set xmllang(String value) { _set_xmllang(this, value); }
  static void _set_xmllang(var _this, String value) native;

  String get xmlspace() { return _get_xmlspace(this); }
  static String _get_xmlspace(var _this) native;

  void set xmlspace(String value) { _set_xmlspace(this, value); }
  static void _set_xmlspace(var _this, String value) native;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return _get_externalResourcesRequired(this); }
  static SVGAnimatedBoolean _get_externalResourcesRequired(var _this) native;

  // From SVGStylable

  SVGAnimatedString get className() { return _get_className(this); }
  static SVGAnimatedString _get_className(var _this) native;

  CSSStyleDeclaration get style() { return _get_style_SVGMarkerElement(this); }
  static CSSStyleDeclaration _get_style_SVGMarkerElement(var _this) native;

  CSSValue getPresentationAttribute(String name) {
    return _getPresentationAttribute(this, name);
  }
  static CSSValue _getPresentationAttribute(receiver, name) native;

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() { return _get_preserveAspectRatio(this); }
  static SVGAnimatedPreserveAspectRatio _get_preserveAspectRatio(var _this) native;

  SVGAnimatedRect get viewBox() { return _get_viewBox(this); }
  static SVGAnimatedRect _get_viewBox(var _this) native;

  String get typeName() { return "SVGMarkerElement"; }
}
