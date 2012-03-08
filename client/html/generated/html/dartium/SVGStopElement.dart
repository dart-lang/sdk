
class _SVGStopElementImpl extends _SVGElementImpl implements SVGStopElement {
  _SVGStopElementImpl._wrap(ptr) : super._wrap(ptr);

  SVGAnimatedNumber get offset() => _wrap(_ptr.offset);

  // From SVGStylable

  SVGAnimatedString get _svgClassName() => _wrap(_ptr.className);

  CSSStyleDeclaration get style() => _wrap(_ptr.style);

  CSSValue getPresentationAttribute(String name) {
    return _wrap(_ptr.getPresentationAttribute(_unwrap(name)));
  }
}
