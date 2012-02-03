
class _SVGPathElementJs extends _SVGElementJs implements SVGPathElement native "*SVGPathElement" {

  _SVGPathSegListJs get animatedNormalizedPathSegList() native "return this.animatedNormalizedPathSegList;";

  _SVGPathSegListJs get animatedPathSegList() native "return this.animatedPathSegList;";

  _SVGPathSegListJs get normalizedPathSegList() native "return this.normalizedPathSegList;";

  _SVGAnimatedNumberJs get pathLength() native "return this.pathLength;";

  _SVGPathSegListJs get pathSegList() native "return this.pathSegList;";

  _SVGPathSegArcAbsJs createSVGPathSegArcAbs(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native;

  _SVGPathSegArcRelJs createSVGPathSegArcRel(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native;

  _SVGPathSegClosePathJs createSVGPathSegClosePath() native;

  _SVGPathSegCurvetoCubicAbsJs createSVGPathSegCurvetoCubicAbs(num x, num y, num x1, num y1, num x2, num y2) native;

  _SVGPathSegCurvetoCubicRelJs createSVGPathSegCurvetoCubicRel(num x, num y, num x1, num y1, num x2, num y2) native;

  _SVGPathSegCurvetoCubicSmoothAbsJs createSVGPathSegCurvetoCubicSmoothAbs(num x, num y, num x2, num y2) native;

  _SVGPathSegCurvetoCubicSmoothRelJs createSVGPathSegCurvetoCubicSmoothRel(num x, num y, num x2, num y2) native;

  _SVGPathSegCurvetoQuadraticAbsJs createSVGPathSegCurvetoQuadraticAbs(num x, num y, num x1, num y1) native;

  _SVGPathSegCurvetoQuadraticRelJs createSVGPathSegCurvetoQuadraticRel(num x, num y, num x1, num y1) native;

  _SVGPathSegCurvetoQuadraticSmoothAbsJs createSVGPathSegCurvetoQuadraticSmoothAbs(num x, num y) native;

  _SVGPathSegCurvetoQuadraticSmoothRelJs createSVGPathSegCurvetoQuadraticSmoothRel(num x, num y) native;

  _SVGPathSegLinetoAbsJs createSVGPathSegLinetoAbs(num x, num y) native;

  _SVGPathSegLinetoHorizontalAbsJs createSVGPathSegLinetoHorizontalAbs(num x) native;

  _SVGPathSegLinetoHorizontalRelJs createSVGPathSegLinetoHorizontalRel(num x) native;

  _SVGPathSegLinetoRelJs createSVGPathSegLinetoRel(num x, num y) native;

  _SVGPathSegLinetoVerticalAbsJs createSVGPathSegLinetoVerticalAbs(num y) native;

  _SVGPathSegLinetoVerticalRelJs createSVGPathSegLinetoVerticalRel(num y) native;

  _SVGPathSegMovetoAbsJs createSVGPathSegMovetoAbs(num x, num y) native;

  _SVGPathSegMovetoRelJs createSVGPathSegMovetoRel(num x, num y) native;

  int getPathSegAtLength(num distance) native;

  _SVGPointJs getPointAtLength(num distance) native;

  num getTotalLength() native;

  // From SVGTests

  _SVGStringListJs get requiredExtensions() native "return this.requiredExtensions;";

  _SVGStringListJs get requiredFeatures() native "return this.requiredFeatures;";

  _SVGStringListJs get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  _SVGAnimatedBooleanJs get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  _SVGAnimatedStringJs get className() native "return this.className;";

  _CSSStyleDeclarationJs get style() native "return this.style;";

  _CSSValueJs getPresentationAttribute(String name) native;

  // From SVGTransformable

  _SVGAnimatedTransformListJs get transform() native "return this.transform;";

  // From SVGLocatable

  _SVGElementJs get farthestViewportElement() native "return this.farthestViewportElement;";

  _SVGElementJs get nearestViewportElement() native "return this.nearestViewportElement;";

  _SVGRectJs getBBox() native;

  _SVGMatrixJs getCTM() native;

  _SVGMatrixJs getScreenCTM() native;

  _SVGMatrixJs getTransformToElement(_SVGElementJs element) native;
}
