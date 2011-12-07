// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFEConvolveMatrixElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGFEConvolveMatrixElement {
  SVGFEConvolveMatrixElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedNumber get bias() { return LevelDom.wrapSVGAnimatedNumber(_ptr.bias); }

  SVGAnimatedNumber get divisor() { return LevelDom.wrapSVGAnimatedNumber(_ptr.divisor); }

  SVGAnimatedEnumeration get edgeMode() { return LevelDom.wrapSVGAnimatedEnumeration(_ptr.edgeMode); }

  SVGAnimatedString get in1() { return LevelDom.wrapSVGAnimatedString(_ptr.in1); }

  SVGAnimatedNumberList get kernelMatrix() { return LevelDom.wrapSVGAnimatedNumberList(_ptr.kernelMatrix); }

  SVGAnimatedNumber get kernelUnitLengthX() { return LevelDom.wrapSVGAnimatedNumber(_ptr.kernelUnitLengthX); }

  SVGAnimatedNumber get kernelUnitLengthY() { return LevelDom.wrapSVGAnimatedNumber(_ptr.kernelUnitLengthY); }

  SVGAnimatedInteger get orderX() { return LevelDom.wrapSVGAnimatedInteger(_ptr.orderX); }

  SVGAnimatedInteger get orderY() { return LevelDom.wrapSVGAnimatedInteger(_ptr.orderY); }

  SVGAnimatedBoolean get preserveAlpha() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.preserveAlpha); }

  SVGAnimatedInteger get targetX() { return LevelDom.wrapSVGAnimatedInteger(_ptr.targetX); }

  SVGAnimatedInteger get targetY() { return LevelDom.wrapSVGAnimatedInteger(_ptr.targetY); }

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
