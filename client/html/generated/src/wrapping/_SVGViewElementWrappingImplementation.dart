// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGViewElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGViewElement {
  SVGViewElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGStringList get viewTarget() { return LevelDom.wrapSVGStringList(_ptr.viewTarget); }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() { return LevelDom.wrapSVGAnimatedPreserveAspectRatio(_ptr.preserveAspectRatio); }

  SVGAnimatedRect get viewBox() { return LevelDom.wrapSVGAnimatedRect(_ptr.viewBox); }

  // From SVGZoomAndPan

  int get zoomAndPan() { return _ptr.zoomAndPan; }

  void set zoomAndPan(int value) { _ptr.zoomAndPan = value; }
}
