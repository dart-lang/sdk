
class _SVGAnimatedAngleImpl extends _DOMTypeBase implements SVGAnimatedAngle {
  _SVGAnimatedAngleImpl._wrap(ptr) : super._wrap(ptr);

  SVGAngle get animVal() => _wrap(_ptr.animVal);

  SVGAngle get baseVal() => _wrap(_ptr.baseVal);
}
