// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGDescElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGDescElement {
  SVGDescElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  // From SVGLangSpace

  String get xmllang() { return _ptr.xmllang; }

  void set xmllang(String value) { _ptr.xmllang = value; }

  String get xmlspace() { return _ptr.xmlspace; }

  void set xmlspace(String value) { _ptr.xmlspace = value; }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }
}
