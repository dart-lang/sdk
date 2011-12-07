// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGGlyphRefElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGGlyphRefElement {
  SVGGlyphRefElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get dx() { return _ptr.dx; }

  void set dx(num value) { _ptr.dx = value; }

  num get dy() { return _ptr.dy; }

  void set dy(num value) { _ptr.dy = value; }

  String get format() { return _ptr.format; }

  void set format(String value) { _ptr.format = value; }

  String get glyphRef() { return _ptr.glyphRef; }

  void set glyphRef(String value) { _ptr.glyphRef = value; }

  num get x() { return _ptr.x; }

  void set x(num value) { _ptr.x = value; }

  num get y() { return _ptr.y; }

  void set y(num value) { _ptr.y = value; }

  // From SVGURIReference

  SVGAnimatedString get href() { return LevelDom.wrapSVGAnimatedString(_ptr.href); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }
}
