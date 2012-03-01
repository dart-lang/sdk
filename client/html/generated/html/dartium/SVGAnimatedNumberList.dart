
class _SVGAnimatedNumberListImpl extends _DOMTypeBase implements SVGAnimatedNumberList {
  _SVGAnimatedNumberListImpl._wrap(ptr) : super._wrap(ptr);

  SVGNumberList get animVal() => _wrap(_ptr.animVal);

  SVGNumberList get baseVal() => _wrap(_ptr.baseVal);
}
