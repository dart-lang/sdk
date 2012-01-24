
class SVGPathElementJS extends SVGElementJS implements SVGPathElement native "*SVGPathElement" {

  SVGPathSegListJS get animatedNormalizedPathSegList() native "return this.animatedNormalizedPathSegList;";

  SVGPathSegListJS get animatedPathSegList() native "return this.animatedPathSegList;";

  SVGPathSegListJS get normalizedPathSegList() native "return this.normalizedPathSegList;";

  SVGAnimatedNumberJS get pathLength() native "return this.pathLength;";

  SVGPathSegListJS get pathSegList() native "return this.pathSegList;";

  SVGPathSegArcAbsJS createSVGPathSegArcAbs(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native;

  SVGPathSegArcRelJS createSVGPathSegArcRel(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native;

  SVGPathSegClosePathJS createSVGPathSegClosePath() native;

  SVGPathSegCurvetoCubicAbsJS createSVGPathSegCurvetoCubicAbs(num x, num y, num x1, num y1, num x2, num y2) native;

  SVGPathSegCurvetoCubicRelJS createSVGPathSegCurvetoCubicRel(num x, num y, num x1, num y1, num x2, num y2) native;

  SVGPathSegCurvetoCubicSmoothAbsJS createSVGPathSegCurvetoCubicSmoothAbs(num x, num y, num x2, num y2) native;

  SVGPathSegCurvetoCubicSmoothRelJS createSVGPathSegCurvetoCubicSmoothRel(num x, num y, num x2, num y2) native;

  SVGPathSegCurvetoQuadraticAbsJS createSVGPathSegCurvetoQuadraticAbs(num x, num y, num x1, num y1) native;

  SVGPathSegCurvetoQuadraticRelJS createSVGPathSegCurvetoQuadraticRel(num x, num y, num x1, num y1) native;

  SVGPathSegCurvetoQuadraticSmoothAbsJS createSVGPathSegCurvetoQuadraticSmoothAbs(num x, num y) native;

  SVGPathSegCurvetoQuadraticSmoothRelJS createSVGPathSegCurvetoQuadraticSmoothRel(num x, num y) native;

  SVGPathSegLinetoAbsJS createSVGPathSegLinetoAbs(num x, num y) native;

  SVGPathSegLinetoHorizontalAbsJS createSVGPathSegLinetoHorizontalAbs(num x) native;

  SVGPathSegLinetoHorizontalRelJS createSVGPathSegLinetoHorizontalRel(num x) native;

  SVGPathSegLinetoRelJS createSVGPathSegLinetoRel(num x, num y) native;

  SVGPathSegLinetoVerticalAbsJS createSVGPathSegLinetoVerticalAbs(num y) native;

  SVGPathSegLinetoVerticalRelJS createSVGPathSegLinetoVerticalRel(num y) native;

  SVGPathSegMovetoAbsJS createSVGPathSegMovetoAbs(num x, num y) native;

  SVGPathSegMovetoRelJS createSVGPathSegMovetoRel(num x, num y) native;

  int getPathSegAtLength(num distance) native;

  SVGPointJS getPointAtLength(num distance) native;

  num getTotalLength() native;

  // From SVGTests

  SVGStringListJS get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringListJS get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringListJS get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBooleanJS get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedStringJS get className() native "return this.className;";

  CSSStyleDeclarationJS get style() native "return this.style;";

  CSSValueJS getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformListJS get transform() native "return this.transform;";

  // From SVGLocatable

  SVGElementJS get farthestViewportElement() native "return this.farthestViewportElement;";

  SVGElementJS get nearestViewportElement() native "return this.nearestViewportElement;";

  SVGRectJS getBBox() native;

  SVGMatrixJS getCTM() native;

  SVGMatrixJS getScreenCTM() native;

  SVGMatrixJS getTransformToElement(SVGElementJS element) native;
}
