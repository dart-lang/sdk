
class _SVGMPathElementImpl extends _SVGElementImpl implements SVGMPathElement {
  _SVGMPathElementImpl._wrap(ptr) : super._wrap(ptr);

  // From SVGURIReference

  SVGAnimatedString get href() => _wrap(_ptr.href);

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() => _wrap(_ptr.externalResourcesRequired);
}
