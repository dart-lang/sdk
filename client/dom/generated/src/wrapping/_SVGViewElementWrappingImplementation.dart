// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGViewElementWrappingImplementation extends _SVGElementWrappingImplementation implements SVGViewElement {
  _SVGViewElementWrappingImplementation() : super() {}

  static create__SVGViewElementWrappingImplementation() native {
    return new _SVGViewElementWrappingImplementation();
  }

  SVGStringList get viewTarget() { return _get_viewTarget(this); }
  static SVGStringList _get_viewTarget(var _this) native;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return _get_externalResourcesRequired(this); }
  static SVGAnimatedBoolean _get_externalResourcesRequired(var _this) native;

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() { return _get_preserveAspectRatio(this); }
  static SVGAnimatedPreserveAspectRatio _get_preserveAspectRatio(var _this) native;

  SVGAnimatedRect get viewBox() { return _get_viewBox(this); }
  static SVGAnimatedRect _get_viewBox(var _this) native;

  // From SVGZoomAndPan

  int get zoomAndPan() { return _get_zoomAndPan(this); }
  static int _get_zoomAndPan(var _this) native;

  void set zoomAndPan(int value) { _set_zoomAndPan(this, value); }
  static void _set_zoomAndPan(var _this, int value) native;

  String get typeName() { return "SVGViewElement"; }
}
