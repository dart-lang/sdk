
class _SVGPathElementImpl extends _SVGElementImpl implements SVGPathElement {
  _SVGPathElementImpl._wrap(ptr) : super._wrap(ptr);

  SVGPathSegList get animatedNormalizedPathSegList() => _wrap(_ptr.animatedNormalizedPathSegList);

  SVGPathSegList get animatedPathSegList() => _wrap(_ptr.animatedPathSegList);

  SVGPathSegList get normalizedPathSegList() => _wrap(_ptr.normalizedPathSegList);

  SVGAnimatedNumber get pathLength() => _wrap(_ptr.pathLength);

  SVGPathSegList get pathSegList() => _wrap(_ptr.pathSegList);

  SVGPathSegArcAbs createSVGPathSegArcAbs(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) {
    return _wrap(_ptr.createSVGPathSegArcAbs(_unwrap(x), _unwrap(y), _unwrap(r1), _unwrap(r2), _unwrap(angle), _unwrap(largeArcFlag), _unwrap(sweepFlag)));
  }

  SVGPathSegArcRel createSVGPathSegArcRel(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) {
    return _wrap(_ptr.createSVGPathSegArcRel(_unwrap(x), _unwrap(y), _unwrap(r1), _unwrap(r2), _unwrap(angle), _unwrap(largeArcFlag), _unwrap(sweepFlag)));
  }

  SVGPathSegClosePath createSVGPathSegClosePath() {
    return _wrap(_ptr.createSVGPathSegClosePath());
  }

  SVGPathSegCurvetoCubicAbs createSVGPathSegCurvetoCubicAbs(num x, num y, num x1, num y1, num x2, num y2) {
    return _wrap(_ptr.createSVGPathSegCurvetoCubicAbs(_unwrap(x), _unwrap(y), _unwrap(x1), _unwrap(y1), _unwrap(x2), _unwrap(y2)));
  }

  SVGPathSegCurvetoCubicRel createSVGPathSegCurvetoCubicRel(num x, num y, num x1, num y1, num x2, num y2) {
    return _wrap(_ptr.createSVGPathSegCurvetoCubicRel(_unwrap(x), _unwrap(y), _unwrap(x1), _unwrap(y1), _unwrap(x2), _unwrap(y2)));
  }

  SVGPathSegCurvetoCubicSmoothAbs createSVGPathSegCurvetoCubicSmoothAbs(num x, num y, num x2, num y2) {
    return _wrap(_ptr.createSVGPathSegCurvetoCubicSmoothAbs(_unwrap(x), _unwrap(y), _unwrap(x2), _unwrap(y2)));
  }

  SVGPathSegCurvetoCubicSmoothRel createSVGPathSegCurvetoCubicSmoothRel(num x, num y, num x2, num y2) {
    return _wrap(_ptr.createSVGPathSegCurvetoCubicSmoothRel(_unwrap(x), _unwrap(y), _unwrap(x2), _unwrap(y2)));
  }

  SVGPathSegCurvetoQuadraticAbs createSVGPathSegCurvetoQuadraticAbs(num x, num y, num x1, num y1) {
    return _wrap(_ptr.createSVGPathSegCurvetoQuadraticAbs(_unwrap(x), _unwrap(y), _unwrap(x1), _unwrap(y1)));
  }

  SVGPathSegCurvetoQuadraticRel createSVGPathSegCurvetoQuadraticRel(num x, num y, num x1, num y1) {
    return _wrap(_ptr.createSVGPathSegCurvetoQuadraticRel(_unwrap(x), _unwrap(y), _unwrap(x1), _unwrap(y1)));
  }

  SVGPathSegCurvetoQuadraticSmoothAbs createSVGPathSegCurvetoQuadraticSmoothAbs(num x, num y) {
    return _wrap(_ptr.createSVGPathSegCurvetoQuadraticSmoothAbs(_unwrap(x), _unwrap(y)));
  }

  SVGPathSegCurvetoQuadraticSmoothRel createSVGPathSegCurvetoQuadraticSmoothRel(num x, num y) {
    return _wrap(_ptr.createSVGPathSegCurvetoQuadraticSmoothRel(_unwrap(x), _unwrap(y)));
  }

  SVGPathSegLinetoAbs createSVGPathSegLinetoAbs(num x, num y) {
    return _wrap(_ptr.createSVGPathSegLinetoAbs(_unwrap(x), _unwrap(y)));
  }

  SVGPathSegLinetoHorizontalAbs createSVGPathSegLinetoHorizontalAbs(num x) {
    return _wrap(_ptr.createSVGPathSegLinetoHorizontalAbs(_unwrap(x)));
  }

  SVGPathSegLinetoHorizontalRel createSVGPathSegLinetoHorizontalRel(num x) {
    return _wrap(_ptr.createSVGPathSegLinetoHorizontalRel(_unwrap(x)));
  }

  SVGPathSegLinetoRel createSVGPathSegLinetoRel(num x, num y) {
    return _wrap(_ptr.createSVGPathSegLinetoRel(_unwrap(x), _unwrap(y)));
  }

  SVGPathSegLinetoVerticalAbs createSVGPathSegLinetoVerticalAbs(num y) {
    return _wrap(_ptr.createSVGPathSegLinetoVerticalAbs(_unwrap(y)));
  }

  SVGPathSegLinetoVerticalRel createSVGPathSegLinetoVerticalRel(num y) {
    return _wrap(_ptr.createSVGPathSegLinetoVerticalRel(_unwrap(y)));
  }

  SVGPathSegMovetoAbs createSVGPathSegMovetoAbs(num x, num y) {
    return _wrap(_ptr.createSVGPathSegMovetoAbs(_unwrap(x), _unwrap(y)));
  }

  SVGPathSegMovetoRel createSVGPathSegMovetoRel(num x, num y) {
    return _wrap(_ptr.createSVGPathSegMovetoRel(_unwrap(x), _unwrap(y)));
  }

  int getPathSegAtLength(num distance) {
    return _wrap(_ptr.getPathSegAtLength(_unwrap(distance)));
  }

  SVGPoint getPointAtLength(num distance) {
    return _wrap(_ptr.getPointAtLength(_unwrap(distance)));
  }

  num getTotalLength() {
    return _wrap(_ptr.getTotalLength());
  }

  // From SVGTests

  SVGStringList get requiredExtensions() => _wrap(_ptr.requiredExtensions);

  SVGStringList get requiredFeatures() => _wrap(_ptr.requiredFeatures);

  SVGStringList get systemLanguage() => _wrap(_ptr.systemLanguage);

  bool hasExtension(String extension) {
    return _wrap(_ptr.hasExtension(_unwrap(extension)));
  }

  // From SVGLangSpace

  String get xmllang() => _wrap(_ptr.xmllang);

  void set xmllang(String value) { _ptr.xmllang = _unwrap(value); }

  String get xmlspace() => _wrap(_ptr.xmlspace);

  void set xmlspace(String value) { _ptr.xmlspace = _unwrap(value); }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() => _wrap(_ptr.externalResourcesRequired);

  // From SVGStylable

  SVGAnimatedString get _svgClassName() => _wrap(_ptr.className);

  CSSStyleDeclaration get style() => _wrap(_ptr.style);

  CSSValue getPresentationAttribute(String name) {
    return _wrap(_ptr.getPresentationAttribute(_unwrap(name)));
  }

  // From SVGTransformable

  SVGAnimatedTransformList get transform() => _wrap(_ptr.transform);

  // From SVGLocatable

  SVGElement get farthestViewportElement() => _wrap(_ptr.farthestViewportElement);

  SVGElement get nearestViewportElement() => _wrap(_ptr.nearestViewportElement);

  SVGRect getBBox() {
    return _wrap(_ptr.getBBox());
  }

  SVGMatrix getCTM() {
    return _wrap(_ptr.getCTM());
  }

  SVGMatrix getScreenCTM() {
    return _wrap(_ptr.getScreenCTM());
  }

  SVGMatrix getTransformToElement(SVGElement element) {
    return _wrap(_ptr.getTransformToElement(_unwrap(element)));
  }
}
