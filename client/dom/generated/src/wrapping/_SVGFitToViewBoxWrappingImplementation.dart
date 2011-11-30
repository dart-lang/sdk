// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGFitToViewBoxWrappingImplementation extends DOMWrapperBase implements SVGFitToViewBox {
  _SVGFitToViewBoxWrappingImplementation() : super() {}

  static create__SVGFitToViewBoxWrappingImplementation() native {
    return new _SVGFitToViewBoxWrappingImplementation();
  }

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() { return _get_preserveAspectRatio(this); }
  static SVGAnimatedPreserveAspectRatio _get_preserveAspectRatio(var _this) native;

  SVGAnimatedRect get viewBox() { return _get_viewBox(this); }
  static SVGAnimatedRect _get_viewBox(var _this) native;

  String get typeName() { return "SVGFitToViewBox"; }
}
