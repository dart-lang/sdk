
class _SVGFETurbulenceElementImpl extends _SVGElementImpl implements SVGFETurbulenceElement {
  _SVGFETurbulenceElementImpl._wrap(ptr) : super._wrap(ptr);

  SVGAnimatedNumber get baseFrequencyX() => _wrap(_ptr.baseFrequencyX);

  SVGAnimatedNumber get baseFrequencyY() => _wrap(_ptr.baseFrequencyY);

  SVGAnimatedInteger get numOctaves() => _wrap(_ptr.numOctaves);

  SVGAnimatedNumber get seed() => _wrap(_ptr.seed);

  SVGAnimatedEnumeration get stitchTiles() => _wrap(_ptr.stitchTiles);

  SVGAnimatedEnumeration get type() => _wrap(_ptr.type);

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
