// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFEDropShadowElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGFEDropShadowElement {
  SVGFEDropShadowElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedNumber get dx() { return LevelDom.wrapSVGAnimatedNumber(_ptr.dx); }

  SVGAnimatedNumber get dy() { return LevelDom.wrapSVGAnimatedNumber(_ptr.dy); }

  SVGAnimatedString get in1() { return LevelDom.wrapSVGAnimatedString(_ptr.in1); }

  SVGAnimatedNumber get stdDeviationX() { return LevelDom.wrapSVGAnimatedNumber(_ptr.stdDeviationX); }

  SVGAnimatedNumber get stdDeviationY() { return LevelDom.wrapSVGAnimatedNumber(_ptr.stdDeviationY); }

  void setStdDeviation(num stdDeviationX, num stdDeviationY) {
    _ptr.setStdDeviation(stdDeviationX, stdDeviationY);
    return;
  }

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() { return LevelDom.wrapSVGAnimatedLength(_ptr.height); }

  SVGAnimatedString get result() { return LevelDom.wrapSVGAnimatedString(_ptr.result); }

  SVGAnimatedLength get width() { return LevelDom.wrapSVGAnimatedLength(_ptr.width); }

  SVGAnimatedLength get x() { return LevelDom.wrapSVGAnimatedLength(_ptr.x); }

  SVGAnimatedLength get y() { return LevelDom.wrapSVGAnimatedLength(_ptr.y); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }
}
