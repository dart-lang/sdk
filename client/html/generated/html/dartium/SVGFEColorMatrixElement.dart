
class _SVGFEColorMatrixElementImpl extends _SVGElementImpl implements SVGFEColorMatrixElement {
  _SVGFEColorMatrixElementImpl._wrap(ptr) : super._wrap(ptr);

  SVGAnimatedString get in1() => _wrap(_ptr.in1);

  SVGAnimatedEnumeration get type() => _wrap(_ptr.type);

  SVGAnimatedNumberList get values() => _wrap(_ptr.values);

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
