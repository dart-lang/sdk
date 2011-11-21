
class SVGPathElement extends SVGElement native "SVGPathElement" {

  SVGPathSegList animatedNormalizedPathSegList;

  SVGPathSegList animatedPathSegList;

  SVGPathSegList normalizedPathSegList;

  SVGAnimatedNumber pathLength;

  SVGPathSegList pathSegList;

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

  SVGStringList requiredExtensions;

  SVGStringList requiredFeatures;

  SVGStringList systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList transform;

  // From SVGLocatable

  SVGElement farthestViewportElement;

  SVGElement nearestViewportElement;

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}
