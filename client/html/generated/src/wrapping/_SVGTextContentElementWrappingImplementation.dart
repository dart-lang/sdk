// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGTextContentElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGTextContentElement {
  SVGTextContentElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedEnumeration get lengthAdjust() { return LevelDom.wrapSVGAnimatedEnumeration(_ptr.lengthAdjust); }

  SVGAnimatedLength get textLength() { return LevelDom.wrapSVGAnimatedLength(_ptr.textLength); }

  int getCharNumAtPosition(SVGPoint point) {
    return _ptr.getCharNumAtPosition(LevelDom.unwrap(point));
  }

  num getComputedTextLength() {
    return _ptr.getComputedTextLength();
  }

  SVGPoint getEndPositionOfChar(int offset) {
    return LevelDom.wrapSVGPoint(_ptr.getEndPositionOfChar(offset));
  }

  SVGRect getExtentOfChar(int offset) {
    return LevelDom.wrapSVGRect(_ptr.getExtentOfChar(offset));
  }

  int getNumberOfChars() {
    return _ptr.getNumberOfChars();
  }

  num getRotationOfChar(int offset) {
    return _ptr.getRotationOfChar(offset);
  }

  SVGPoint getStartPositionOfChar(int offset) {
    return LevelDom.wrapSVGPoint(_ptr.getStartPositionOfChar(offset));
  }

  num getSubStringLength(int offset, int length) {
    return _ptr.getSubStringLength(offset, length);
  }

  void selectSubString(int offset, int length) {
    _ptr.selectSubString(offset, length);
    return;
  }

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
}
