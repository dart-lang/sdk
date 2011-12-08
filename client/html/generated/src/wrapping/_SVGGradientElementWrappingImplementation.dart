// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGGradientElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGGradientElement {
  SVGGradientElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedTransformList get gradientTransform() { return LevelDom.wrapSVGAnimatedTransformList(_ptr.gradientTransform); }

  SVGAnimatedEnumeration get gradientUnits() { return LevelDom.wrapSVGAnimatedEnumeration(_ptr.gradientUnits); }

  SVGAnimatedEnumeration get spreadMethod() { return LevelDom.wrapSVGAnimatedEnumeration(_ptr.spreadMethod); }

  // From SVGURIReference

  SVGAnimatedString get href() { return LevelDom.wrapSVGAnimatedString(_ptr.href); }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }
}
