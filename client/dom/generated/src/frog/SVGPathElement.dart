
class SVGPathElementJs extends SVGElementJs implements SVGPathElement native "*SVGPathElement" {

  SVGPathSegListJs get animatedNormalizedPathSegList() native "return this.animatedNormalizedPathSegList;";

  SVGPathSegListJs get animatedPathSegList() native "return this.animatedPathSegList;";

  SVGPathSegListJs get normalizedPathSegList() native "return this.normalizedPathSegList;";

  SVGAnimatedNumberJs get pathLength() native "return this.pathLength;";

  SVGPathSegListJs get pathSegList() native "return this.pathSegList;";

  SVGPathSegArcAbsJs createSVGPathSegArcAbs(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native;

  SVGPathSegArcRelJs createSVGPathSegArcRel(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native;

  SVGPathSegClosePathJs createSVGPathSegClosePath() native;

  SVGPathSegCurvetoCubicAbsJs createSVGPathSegCurvetoCubicAbs(num x, num y, num x1, num y1, num x2, num y2) native;

  SVGPathSegCurvetoCubicRelJs createSVGPathSegCurvetoCubicRel(num x, num y, num x1, num y1, num x2, num y2) native;

  SVGPathSegCurvetoCubicSmoothAbsJs createSVGPathSegCurvetoCubicSmoothAbs(num x, num y, num x2, num y2) native;

  SVGPathSegCurvetoCubicSmoothRelJs createSVGPathSegCurvetoCubicSmoothRel(num x, num y, num x2, num y2) native;

  SVGPathSegCurvetoQuadraticAbsJs createSVGPathSegCurvetoQuadraticAbs(num x, num y, num x1, num y1) native;

  SVGPathSegCurvetoQuadraticRelJs createSVGPathSegCurvetoQuadraticRel(num x, num y, num x1, num y1) native;

  SVGPathSegCurvetoQuadraticSmoothAbsJs createSVGPathSegCurvetoQuadraticSmoothAbs(num x, num y) native;

  SVGPathSegCurvetoQuadraticSmoothRelJs createSVGPathSegCurvetoQuadraticSmoothRel(num x, num y) native;

  SVGPathSegLinetoAbsJs createSVGPathSegLinetoAbs(num x, num y) native;

  SVGPathSegLinetoHorizontalAbsJs createSVGPathSegLinetoHorizontalAbs(num x) native;

  SVGPathSegLinetoHorizontalRelJs createSVGPathSegLinetoHorizontalRel(num x) native;

  SVGPathSegLinetoRelJs createSVGPathSegLinetoRel(num x, num y) native;

  SVGPathSegLinetoVerticalAbsJs createSVGPathSegLinetoVerticalAbs(num y) native;

  SVGPathSegLinetoVerticalRelJs createSVGPathSegLinetoVerticalRel(num y) native;

  SVGPathSegMovetoAbsJs createSVGPathSegMovetoAbs(num x, num y) native;

  SVGPathSegMovetoRelJs createSVGPathSegMovetoRel(num x, num y) native;

  int getPathSegAtLength(num distance) native;

  SVGPointJs getPointAtLength(num distance) native;

  num getTotalLength() native;

  // From SVGTests

  SVGStringListJs get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringListJs get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringListJs get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBooleanJs get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedStringJs get className() native "return this.className;";

  CSSStyleDeclarationJs get style() native "return this.style;";

  CSSValueJs getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformListJs get transform() native "return this.transform;";

  // From SVGLocatable

  SVGElementJs get farthestViewportElement() native "return this.farthestViewportElement;";

  SVGElementJs get nearestViewportElement() native "return this.nearestViewportElement;";

  SVGRectJs getBBox() native;

  SVGMatrixJs getCTM() native;

  SVGMatrixJs getScreenCTM() native;

  SVGMatrixJs getTransformToElement(SVGElementJs element) native;
}
