
class _SVGAnimatedTransformListImpl extends _DOMTypeBase implements SVGAnimatedTransformList {
  _SVGAnimatedTransformListImpl._wrap(ptr) : super._wrap(ptr);

  SVGTransformList get animVal() => _wrap(_ptr.animVal);

  SVGTransformList get baseVal() => _wrap(_ptr.baseVal);
}
