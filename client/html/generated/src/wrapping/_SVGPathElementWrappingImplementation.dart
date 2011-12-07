// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPathElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGPathElement {
  SVGPathElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGPathSegList get animatedNormalizedPathSegList() { return LevelDom.wrapSVGPathSegList(_ptr.animatedNormalizedPathSegList); }

  SVGPathSegList get animatedPathSegList() { return LevelDom.wrapSVGPathSegList(_ptr.animatedPathSegList); }

  SVGPathSegList get normalizedPathSegList() { return LevelDom.wrapSVGPathSegList(_ptr.normalizedPathSegList); }

  SVGAnimatedNumber get pathLength() { return LevelDom.wrapSVGAnimatedNumber(_ptr.pathLength); }

  SVGPathSegList get pathSegList() { return LevelDom.wrapSVGPathSegList(_ptr.pathSegList); }

  SVGPathSegArcAbs createSVGPathSegArcAbs(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) {
    return LevelDom.wrapSVGPathSegArcAbs(_ptr.createSVGPathSegArcAbs(x, y, r1, r2, angle, largeArcFlag, sweepFlag));
  }

  SVGPathSegArcRel createSVGPathSegArcRel(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) {
    return LevelDom.wrapSVGPathSegArcRel(_ptr.createSVGPathSegArcRel(x, y, r1, r2, angle, largeArcFlag, sweepFlag));
  }

  SVGPathSegClosePath createSVGPathSegClosePath() {
    return LevelDom.wrapSVGPathSegClosePath(_ptr.createSVGPathSegClosePath());
  }

  SVGPathSegCurvetoCubicAbs createSVGPathSegCurvetoCubicAbs(num x, num y, num x1, num y1, num x2, num y2) {
    return LevelDom.wrapSVGPathSegCurvetoCubicAbs(_ptr.createSVGPathSegCurvetoCubicAbs(x, y, x1, y1, x2, y2));
  }

  SVGPathSegCurvetoCubicRel createSVGPathSegCurvetoCubicRel(num x, num y, num x1, num y1, num x2, num y2) {
    return LevelDom.wrapSVGPathSegCurvetoCubicRel(_ptr.createSVGPathSegCurvetoCubicRel(x, y, x1, y1, x2, y2));
  }

  SVGPathSegCurvetoCubicSmoothAbs createSVGPathSegCurvetoCubicSmoothAbs(num x, num y, num x2, num y2) {
    return LevelDom.wrapSVGPathSegCurvetoCubicSmoothAbs(_ptr.createSVGPathSegCurvetoCubicSmoothAbs(x, y, x2, y2));
  }

  SVGPathSegCurvetoCubicSmoothRel createSVGPathSegCurvetoCubicSmoothRel(num x, num y, num x2, num y2) {
    return LevelDom.wrapSVGPathSegCurvetoCubicSmoothRel(_ptr.createSVGPathSegCurvetoCubicSmoothRel(x, y, x2, y2));
  }

  SVGPathSegCurvetoQuadraticAbs createSVGPathSegCurvetoQuadraticAbs(num x, num y, num x1, num y1) {
    return LevelDom.wrapSVGPathSegCurvetoQuadraticAbs(_ptr.createSVGPathSegCurvetoQuadraticAbs(x, y, x1, y1));
  }

  SVGPathSegCurvetoQuadraticRel createSVGPathSegCurvetoQuadraticRel(num x, num y, num x1, num y1) {
    return LevelDom.wrapSVGPathSegCurvetoQuadraticRel(_ptr.createSVGPathSegCurvetoQuadraticRel(x, y, x1, y1));
  }

  SVGPathSegCurvetoQuadraticSmoothAbs createSVGPathSegCurvetoQuadraticSmoothAbs(num x, num y) {
    return LevelDom.wrapSVGPathSegCurvetoQuadraticSmoothAbs(_ptr.createSVGPathSegCurvetoQuadraticSmoothAbs(x, y));
  }

  SVGPathSegCurvetoQuadraticSmoothRel createSVGPathSegCurvetoQuadraticSmoothRel(num x, num y) {
    return LevelDom.wrapSVGPathSegCurvetoQuadraticSmoothRel(_ptr.createSVGPathSegCurvetoQuadraticSmoothRel(x, y));
  }

  SVGPathSegLinetoAbs createSVGPathSegLinetoAbs(num x, num y) {
    return LevelDom.wrapSVGPathSegLinetoAbs(_ptr.createSVGPathSegLinetoAbs(x, y));
  }

  SVGPathSegLinetoHorizontalAbs createSVGPathSegLinetoHorizontalAbs(num x) {
    return LevelDom.wrapSVGPathSegLinetoHorizontalAbs(_ptr.createSVGPathSegLinetoHorizontalAbs(x));
  }

  SVGPathSegLinetoHorizontalRel createSVGPathSegLinetoHorizontalRel(num x) {
    return LevelDom.wrapSVGPathSegLinetoHorizontalRel(_ptr.createSVGPathSegLinetoHorizontalRel(x));
  }

  SVGPathSegLinetoRel createSVGPathSegLinetoRel(num x, num y) {
    return LevelDom.wrapSVGPathSegLinetoRel(_ptr.createSVGPathSegLinetoRel(x, y));
  }

  SVGPathSegLinetoVerticalAbs createSVGPathSegLinetoVerticalAbs(num y) {
    return LevelDom.wrapSVGPathSegLinetoVerticalAbs(_ptr.createSVGPathSegLinetoVerticalAbs(y));
  }

  SVGPathSegLinetoVerticalRel createSVGPathSegLinetoVerticalRel(num y) {
    return LevelDom.wrapSVGPathSegLinetoVerticalRel(_ptr.createSVGPathSegLinetoVerticalRel(y));
  }

  SVGPathSegMovetoAbs createSVGPathSegMovetoAbs(num x, num y) {
    return LevelDom.wrapSVGPathSegMovetoAbs(_ptr.createSVGPathSegMovetoAbs(x, y));
  }

  SVGPathSegMovetoRel createSVGPathSegMovetoRel(num x, num y) {
    return LevelDom.wrapSVGPathSegMovetoRel(_ptr.createSVGPathSegMovetoRel(x, y));
  }

  int getPathSegAtLength(num distance) {
    return _ptr.getPathSegAtLength(distance);
  }

  SVGPoint getPointAtLength(num distance) {
    return LevelDom.wrapSVGPoint(_ptr.getPointAtLength(distance));
  }

  num getTotalLength() {
    return _ptr.getTotalLength();
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
