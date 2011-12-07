// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGTextElementWrappingImplementation extends SVGTextPositioningElementWrappingImplementation implements SVGTextElement {
  SVGTextElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  // From SVGTransformable

  SVGAnimatedTransformList get transform() { return LevelDom.wrapSVGAnimatedTransformList(_ptr.transform); }

  // From SVGLocatable

  SVGElement get farthestViewportElement() { return LevelDom.wrapSVGElement(_ptr.farthestViewportElement); }

  SVGElement get nearestViewportElement() { return LevelDom.wrapSVGElement(_ptr.nearestViewportElement); }

  SVGRect getBBox() {
    return LevelDom.wrapSVGRect(_ptr.getBBox());
  }

  SVGMatrix getCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getCTM());
  }

  SVGMatrix getScreenCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getScreenCTM());
  }

  SVGMatrix getTransformToElement(SVGElement element) {
    return LevelDom.wrapSVGMatrix(_ptr.getTransformToElement(LevelDom.unwrap(element)));
  }
}
