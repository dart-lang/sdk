
class SVGPathElement extends SVGElement native "*SVGPathElement" {

  SVGPathSegList get animatedNormalizedPathSegList() native "return this.animatedNormalizedPathSegList;";

  SVGPathSegList get animatedPathSegList() native "return this.animatedPathSegList;";

  SVGPathSegList get normalizedPathSegList() native "return this.normalizedPathSegList;";

  SVGAnimatedNumber get pathLength() native "return this.pathLength;";

  SVGPathSegList get pathSegList() native "return this.pathSegList;";

  SVGPathSegArcAbs createSVGPathSegArcAbs(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native;

  SVGPathSegArcRel createSVGPathSegArcRel(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native;

  SVGPathSegClosePath createSVGPathSegClosePath() native;

  SVGPathSegCurvetoCubicAbs createSVGPathSegCurvetoCubicAbs(num x, num y, num x1, num y1, num x2, num y2) native;

  SVGPathSegCurvetoCubicRel createSVGPathSegCurvetoCubicRel(num x, num y, num x1, num y1, num x2, num y2) native;

  SVGPathSegCurvetoCubicSmoothAbs createSVGPathSegCurvetoCubicSmoothAbs(num x, num y, num x2, num y2) native;

  SVGPathSegCurvetoCubicSmoothRel createSVGPathSegCurvetoCubicSmoothRel(num x, num y, num x2, num y2) native;

  SVGPathSegCurvetoQuadraticAbs createSVGPathSegCurvetoQuadraticAbs(num x, num y, num x1, num y1) native;

  SVGPathSegCurvetoQuadraticRel createSVGPathSegCurvetoQuadraticRel(num x, num y, num x1, num y1) native;

  SVGPathSegCurvetoQuadraticSmoothAbs createSVGPathSegCurvetoQuadraticSmoothAbs(num x, num y) native;

  SVGPathSegCurvetoQuadraticSmoothRel createSVGPathSegCurvetoQuadraticSmoothRel(num x, num y) native;

  SVGPathSegLinetoAbs createSVGPathSegLinetoAbs(num x, num y) native;

  SVGPathSegLinetoHorizontalAbs createSVGPathSegLinetoHorizontalAbs(num x) native;

  SVGPathSegLinetoHorizontalRel createSVGPathSegLinetoHorizontalRel(num x) native;

  SVGPathSegLinetoRel createSVGPathSegLinetoRel(num x, num y) native;

  SVGPathSegLinetoVerticalAbs createSVGPathSegLinetoVerticalAbs(num y) native;

  SVGPathSegLinetoVerticalRel createSVGPathSegLinetoVerticalRel(num y) native;

  SVGPathSegMovetoAbs createSVGPathSegMovetoAbs(num x, num y) native;

  SVGPathSegMovetoRel createSVGPathSegMovetoRel(num x, num y) native;

  int getPathSegAtLength(num distance) native;

  SVGPoint getPointAtLength(num distance) native;

  num getTotalLength() native;

  // From SVGTests

  SVGStringList get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringList get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringList get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList get transform() native "return this.transform;";

  // From SVGLocatable

  SVGElement get farthestViewportElement() native "return this.farthestViewportElement;";

  SVGElement get nearestViewportElement() native "return this.nearestViewportElement;";

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}
