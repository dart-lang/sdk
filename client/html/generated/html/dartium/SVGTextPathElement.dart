
class _SVGTextPathElementImpl extends _SVGTextContentElementImpl implements SVGTextPathElement {
  _SVGTextPathElementImpl._wrap(ptr) : super._wrap(ptr);

  SVGAnimatedEnumeration get method() => _wrap(_ptr.method);

  SVGAnimatedEnumeration get spacing() => _wrap(_ptr.spacing);

  SVGAnimatedLength get startOffset() => _wrap(_ptr.startOffset);

  // From SVGURIReference

  SVGAnimatedString get href() => _wrap(_ptr.href);
}
