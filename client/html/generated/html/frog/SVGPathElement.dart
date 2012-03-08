
class _SVGPathElementImpl extends _SVGElementImpl implements SVGPathElement native "*SVGPathElement" {

  final _SVGPathSegListImpl animatedNormalizedPathSegList;

  final _SVGPathSegListImpl animatedPathSegList;

  final _SVGPathSegListImpl normalizedPathSegList;

  final _SVGAnimatedNumberImpl pathLength;

  final _SVGPathSegListImpl pathSegList;

  _SVGPathSegArcAbsImpl createSVGPathSegArcAbs(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native;

  _SVGPathSegArcRelImpl createSVGPathSegArcRel(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native;

  _SVGPathSegClosePathImpl createSVGPathSegClosePath() native;

  _SVGPathSegCurvetoCubicAbsImpl createSVGPathSegCurvetoCubicAbs(num x, num y, num x1, num y1, num x2, num y2) native;

  _SVGPathSegCurvetoCubicRelImpl createSVGPathSegCurvetoCubicRel(num x, num y, num x1, num y1, num x2, num y2) native;

  _SVGPathSegCurvetoCubicSmoothAbsImpl createSVGPathSegCurvetoCubicSmoothAbs(num x, num y, num x2, num y2) native;

  _SVGPathSegCurvetoCubicSmoothRelImpl createSVGPathSegCurvetoCubicSmoothRel(num x, num y, num x2, num y2) native;

  _SVGPathSegCurvetoQuadraticAbsImpl createSVGPathSegCurvetoQuadraticAbs(num x, num y, num x1, num y1) native;

  _SVGPathSegCurvetoQuadraticRelImpl createSVGPathSegCurvetoQuadraticRel(num x, num y, num x1, num y1) native;

  _SVGPathSegCurvetoQuadraticSmoothAbsImpl createSVGPathSegCurvetoQuadraticSmoothAbs(num x, num y) native;

  _SVGPathSegCurvetoQuadraticSmoothRelImpl createSVGPathSegCurvetoQuadraticSmoothRel(num x, num y) native;

  _SVGPathSegLinetoAbsImpl createSVGPathSegLinetoAbs(num x, num y) native;

  _SVGPathSegLinetoHorizontalAbsImpl createSVGPathSegLinetoHorizontalAbs(num x) native;

  _SVGPathSegLinetoHorizontalRelImpl createSVGPathSegLinetoHorizontalRel(num x) native;

  _SVGPathSegLinetoRelImpl createSVGPathSegLinetoRel(num x, num y) native;

  _SVGPathSegLinetoVerticalAbsImpl createSVGPathSegLinetoVerticalAbs(num y) native;

  _SVGPathSegLinetoVerticalRelImpl createSVGPathSegLinetoVerticalRel(num y) native;

  _SVGPathSegMovetoAbsImpl createSVGPathSegMovetoAbs(num x, num y) native;

  _SVGPathSegMovetoRelImpl createSVGPathSegMovetoRel(num x, num y) native;

  int getPathSegAtLength(num distance) native;

  _SVGPointImpl getPointAtLength(num distance) native;

  num getTotalLength() native;

  // From SVGTests

  final _SVGStringListImpl requiredExtensions;

  final _SVGStringListImpl requiredFeatures;

  final _SVGStringListImpl systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From SVGStylable

  _SVGAnimatedStringImpl get _svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListImpl transform;

  // From SVGLocatable

  final _SVGElementImpl farthestViewportElement;

  final _SVGElementImpl nearestViewportElement;

  _SVGRectImpl getBBox() native;

  _SVGMatrixImpl getCTM() native;

  _SVGMatrixImpl getScreenCTM() native;

  _SVGMatrixImpl getTransformToElement(_SVGElementImpl element) native;
}
