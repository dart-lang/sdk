
class _SVGAnimatedLengthImpl extends _DOMTypeBase implements SVGAnimatedLength {
  _SVGAnimatedLengthImpl._wrap(ptr) : super._wrap(ptr);

  SVGLength get animVal() => _wrap(_ptr.animVal);

  SVGLength get baseVal() => _wrap(_ptr.baseVal);
}
