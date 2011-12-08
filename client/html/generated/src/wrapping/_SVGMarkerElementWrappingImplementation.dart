// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGMarkerElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGMarkerElement {
  SVGMarkerElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedLength get markerHeight() { return LevelDom.wrapSVGAnimatedLength(_ptr.markerHeight); }

  SVGAnimatedEnumeration get markerUnits() { return LevelDom.wrapSVGAnimatedEnumeration(_ptr.markerUnits); }

  SVGAnimatedLength get markerWidth() { return LevelDom.wrapSVGAnimatedLength(_ptr.markerWidth); }

  SVGAnimatedAngle get orientAngle() { return LevelDom.wrapSVGAnimatedAngle(_ptr.orientAngle); }

  SVGAnimatedEnumeration get orientType() { return LevelDom.wrapSVGAnimatedEnumeration(_ptr.orientType); }

  SVGAnimatedLength get refX() { return LevelDom.wrapSVGAnimatedLength(_ptr.refX); }

  SVGAnimatedLength get refY() { return LevelDom.wrapSVGAnimatedLength(_ptr.refY); }

  void setOrientToAngle(SVGAngle angle) {
    _ptr.setOrientToAngle(LevelDom.unwrap(angle));
    return;
  }

  void setOrientToAuto() {
    _ptr.setOrientToAuto();
    return;
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

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() { return LevelDom.wrapSVGAnimatedPreserveAspectRatio(_ptr.preserveAspectRatio); }

  SVGAnimatedRect get viewBox() { return LevelDom.wrapSVGAnimatedRect(_ptr.viewBox); }
}
