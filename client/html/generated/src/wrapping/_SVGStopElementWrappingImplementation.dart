// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGStopElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGStopElement {
  SVGStopElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedNumber get offset() { return LevelDom.wrapSVGAnimatedNumber(_ptr.offset); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }
}
