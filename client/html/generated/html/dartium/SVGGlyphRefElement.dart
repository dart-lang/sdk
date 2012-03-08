
class _SVGGlyphRefElementImpl extends _SVGElementImpl implements SVGGlyphRefElement {
  _SVGGlyphRefElementImpl._wrap(ptr) : super._wrap(ptr);

  num get dx() => _wrap(_ptr.dx);

  void set dx(num value) { _ptr.dx = _unwrap(value); }

  num get dy() => _wrap(_ptr.dy);

  void set dy(num value) { _ptr.dy = _unwrap(value); }

  String get format() => _wrap(_ptr.format);

  void set format(String value) { _ptr.format = _unwrap(value); }

  String get glyphRef() => _wrap(_ptr.glyphRef);

  void set glyphRef(String value) { _ptr.glyphRef = _unwrap(value); }

  num get x() => _wrap(_ptr.x);

  void set x(num value) { _ptr.x = _unwrap(value); }

  num get y() => _wrap(_ptr.y);

  void set y(num value) { _ptr.y = _unwrap(value); }

  // From SVGURIReference

  SVGAnimatedString get href() => _wrap(_ptr.href);

  // From SVGStylable

  SVGAnimatedString get _svgClassName() => _wrap(_ptr.className);

  CSSStyleDeclaration get style() => _wrap(_ptr.style);

  CSSValue getPresentationAttribute(String name) {
    return _wrap(_ptr.getPresentationAttribute(_unwrap(name)));
  }
}
