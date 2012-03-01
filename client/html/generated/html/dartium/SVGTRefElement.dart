
class _SVGTRefElementImpl extends _SVGTextPositioningElementImpl implements SVGTRefElement {
  _SVGTRefElementImpl._wrap(ptr) : super._wrap(ptr);

  // From SVGURIReference

  SVGAnimatedString get href() => _wrap(_ptr.href);
}
