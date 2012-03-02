
class _SVGTextElementImpl extends _SVGTextPositioningElementImpl implements SVGTextElement {
  _SVGTextElementImpl._wrap(ptr) : super._wrap(ptr);

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
