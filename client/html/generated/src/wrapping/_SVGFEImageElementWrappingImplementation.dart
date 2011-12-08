// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFEImageElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGFEImageElement {
  SVGFEImageElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() { return LevelDom.wrapSVGAnimatedPreserveAspectRatio(_ptr.preserveAspectRatio); }

  // From SVGURIReference

  SVGAnimatedString get href() { return LevelDom.wrapSVGAnimatedString(_ptr.href); }

  // From SVGLangSpace

  String get xmllang() { return _ptr.xmllang; }

  void set xmllang(String value) { _ptr.xmllang = value; }

  String get xmlspace() { return _ptr.xmlspace; }

  void set xmlspace(String value) { _ptr.xmlspace = value; }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

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
