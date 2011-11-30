// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGViewSpecWrappingImplementation extends _SVGZoomAndPanWrappingImplementation implements SVGViewSpec {
  _SVGViewSpecWrappingImplementation() : super() {}

  static create__SVGViewSpecWrappingImplementation() native {
    return new _SVGViewSpecWrappingImplementation();
  }

  String get preserveAspectRatioString() { return _get_preserveAspectRatioString(this); }
  static String _get_preserveAspectRatioString(var _this) native;

  SVGTransformList get transform() { return _get_transform(this); }
  static SVGTransformList _get_transform(var _this) native;

  String get transformString() { return _get_transformString(this); }
  static String _get_transformString(var _this) native;

  String get viewBoxString() { return _get_viewBoxString(this); }
  static String _get_viewBoxString(var _this) native;

  SVGElement get viewTarget() { return _get_viewTarget(this); }
  static SVGElement _get_viewTarget(var _this) native;

  String get viewTargetString() { return _get_viewTargetString(this); }
  static String _get_viewTargetString(var _this) native;

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() { return _get_preserveAspectRatio(this); }
  static SVGAnimatedPreserveAspectRatio _get_preserveAspectRatio(var _this) native;

  SVGAnimatedRect get viewBox() { return _get_viewBox(this); }
  static SVGAnimatedRect _get_viewBox(var _this) native;

  String get typeName() { return "SVGViewSpec"; }
}
