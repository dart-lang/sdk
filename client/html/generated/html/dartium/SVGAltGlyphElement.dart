
class _SVGAltGlyphElementImpl extends _SVGTextPositioningElementImpl implements SVGAltGlyphElement {
  _SVGAltGlyphElementImpl._wrap(ptr) : super._wrap(ptr);

  String get format() => _wrap(_ptr.format);

  void set format(String value) { _ptr.format = _unwrap(value); }

  String get glyphRef() => _wrap(_ptr.glyphRef);

  void set glyphRef(String value) { _ptr.glyphRef = _unwrap(value); }

  // From SVGURIReference

  SVGAnimatedString get href() => _wrap(_ptr.href);
}
