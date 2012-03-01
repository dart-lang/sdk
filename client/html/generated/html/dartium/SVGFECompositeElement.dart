
class _SVGFECompositeElementImpl extends _SVGElementImpl implements SVGFECompositeElement {
  _SVGFECompositeElementImpl._wrap(ptr) : super._wrap(ptr);

  SVGAnimatedString get in1() => _wrap(_ptr.in1);

  SVGAnimatedString get in2() => _wrap(_ptr.in2);

  SVGAnimatedNumber get k1() => _wrap(_ptr.k1);

  SVGAnimatedNumber get k2() => _wrap(_ptr.k2);

  SVGAnimatedNumber get k3() => _wrap(_ptr.k3);

  SVGAnimatedNumber get k4() => _wrap(_ptr.k4);

  SVGAnimatedEnumeration get operator() => _wrap(_ptr.operator);

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() => _wrap(_ptr.height);

  SVGAnimatedString get result() => _wrap(_ptr.result);

  SVGAnimatedLength get width() => _wrap(_ptr.width);

  SVGAnimatedLength get x() => _wrap(_ptr.x);

  SVGAnimatedLength get y() => _wrap(_ptr.y);

  // From SVGStylable

  SVGAnimatedString get _className() => _wrap(_ptr.className);

  CSSStyleDeclaration get style() => _wrap(_ptr.style);

  CSSValue getPresentationAttribute(String name) {
    return _wrap(_ptr.getPresentationAttribute(_unwrap(name)));
  }
}
