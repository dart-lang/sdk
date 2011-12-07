// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGAltGlyphElementWrappingImplementation extends SVGTextPositioningElementWrappingImplementation implements SVGAltGlyphElement {
  SVGAltGlyphElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get format() { return _ptr.format; }

  void set format(String value) { _ptr.format = value; }

  String get glyphRef() { return _ptr.glyphRef; }

  void set glyphRef(String value) { _ptr.glyphRef = value; }

  // From SVGURIReference

  SVGAnimatedString get href() { return LevelDom.wrapSVGAnimatedString(_ptr.href); }
}
