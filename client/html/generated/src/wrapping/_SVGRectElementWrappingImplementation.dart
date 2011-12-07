// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGRectElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGRectElement {
  SVGRectElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedLength get height() { return LevelDom.wrapSVGAnimatedLength(_ptr.height); }

  SVGAnimatedLength get rx() { return LevelDom.wrapSVGAnimatedLength(_ptr.rx); }

  SVGAnimatedLength get ry() { return LevelDom.wrapSVGAnimatedLength(_ptr.ry); }

  SVGAnimatedLength get width() { return LevelDom.wrapSVGAnimatedLength(_ptr.width); }

  SVGAnimatedLength get x() { return LevelDom.wrapSVGAnimatedLength(_ptr.x); }

  SVGAnimatedLength get y() { return LevelDom.wrapSVGAnimatedLength(_ptr.y); }

  // From SVGTests

  SVGStringList get requiredExtensions() { return LevelDom.wrapSVGStringList(_ptr.requiredExtensions); }

  SVGStringList get requiredFeatures() { return LevelDom.wrapSVGStringList(_ptr.requiredFeatures); }

  SVGStringList get systemLanguage() { return LevelDom.wrapSVGStringList(_ptr.systemLanguage); }

  bool hasExtension(String extension) {
    return _ptr.hasExtension(extension);
  }

  // From SVGLangSpace

  String get xmllang() { return _ptr.xmllang; }

  void set xmllang(String value) { _ptr.xmllang = value; }

  String get xmlspace() { return _ptr.xmlspace; }

  void set xmlspace(String value) { _ptr.xmlspace = value; }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }

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
