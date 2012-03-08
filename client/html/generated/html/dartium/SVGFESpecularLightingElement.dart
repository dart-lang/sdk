
class _SVGFESpecularLightingElementImpl extends _SVGElementImpl implements SVGFESpecularLightingElement {
  _SVGFESpecularLightingElementImpl._wrap(ptr) : super._wrap(ptr);

  SVGAnimatedString get in1() => _wrap(_ptr.in1);

  SVGAnimatedNumber get specularConstant() => _wrap(_ptr.specularConstant);

  SVGAnimatedNumber get specularExponent() => _wrap(_ptr.specularExponent);

  SVGAnimatedNumber get surfaceScale() => _wrap(_ptr.surfaceScale);

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
