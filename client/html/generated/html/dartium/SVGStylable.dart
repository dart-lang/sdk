
class _SVGStylableImpl extends _DOMTypeBase implements SVGStylable {
  _SVGStylableImpl._wrap(ptr) : super._wrap(ptr);

  SVGAnimatedString get _svgClassName() => _wrap(_ptr.className);

  CSSStyleDeclaration get style() => _wrap(_ptr.style);

  CSSValue getPresentationAttribute(String name) {
    return _wrap(_ptr.getPresentationAttribute(_unwrap(name)));
  }
}
