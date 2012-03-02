
class _SVGURIReferenceImpl extends _DOMTypeBase implements SVGURIReference {
  _SVGURIReferenceImpl._wrap(ptr) : super._wrap(ptr);

  SVGAnimatedString get href() => _wrap(_ptr.href);
}
