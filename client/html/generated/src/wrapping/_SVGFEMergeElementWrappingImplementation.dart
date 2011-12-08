// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFEMergeElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGFEMergeElement {
  SVGFEMergeElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

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
