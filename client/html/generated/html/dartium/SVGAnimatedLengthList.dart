
class _SVGAnimatedLengthListImpl extends _DOMTypeBase implements SVGAnimatedLengthList {
  _SVGAnimatedLengthListImpl._wrap(ptr) : super._wrap(ptr);

  SVGLengthList get animVal() => _wrap(_ptr.animVal);

  SVGLengthList get baseVal() => _wrap(_ptr.baseVal);
}
