
class _SVGFEMorphologyElementImpl extends _SVGElementImpl implements SVGFEMorphologyElement {
  _SVGFEMorphologyElementImpl._wrap(ptr) : super._wrap(ptr);

  SVGAnimatedString get in1() => _wrap(_ptr.in1);

  SVGAnimatedEnumeration get operator() => _wrap(_ptr.operator);

  SVGAnimatedNumber get radiusX() => _wrap(_ptr.radiusX);

  SVGAnimatedNumber get radiusY() => _wrap(_ptr.radiusY);

  void setRadius(num radiusX, num radiusY) {
    _ptr.setRadius(_unwrap(radiusX), _unwrap(radiusY));
    return;
  }

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() => _wrap(_ptr.height);

  SVGAnimatedString get result() => _wrap(_ptr.result);

  SVGAnimatedLength get width() => _wrap(_ptr.width);

  SVGAnimatedLength get x() => _wrap(_ptr.x);

  SVGAnimatedLength get y() => _wrap(_ptr.y);

  // From SVGStylable

  SVGAnimatedString get _svgClassName() => _wrap(_ptr.className);

  CSSStyleDeclaration get style() => _wrap(_ptr.style);

  CSSValue getPresentationAttribute(String name) {
    return _wrap(_ptr.getPresentationAttribute(_unwrap(name)));
  }
}
