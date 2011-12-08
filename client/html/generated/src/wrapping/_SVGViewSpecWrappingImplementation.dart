// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGViewSpecWrappingImplementation extends SVGZoomAndPanWrappingImplementation implements SVGViewSpec {
  SVGViewSpecWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get preserveAspectRatioString() { return _ptr.preserveAspectRatioString; }

  SVGTransformList get transform() { return LevelDom.wrapSVGTransformList(_ptr.transform); }

  String get transformString() { return _ptr.transformString; }

  String get viewBoxString() { return _ptr.viewBoxString; }

  SVGElement get viewTarget() { return LevelDom.wrapSVGElement(_ptr.viewTarget); }

  String get viewTargetString() { return _ptr.viewTargetString; }

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() { return LevelDom.wrapSVGAnimatedPreserveAspectRatio(_ptr.preserveAspectRatio); }

  SVGAnimatedRect get viewBox() { return LevelDom.wrapSVGAnimatedRect(_ptr.viewBox); }
}
