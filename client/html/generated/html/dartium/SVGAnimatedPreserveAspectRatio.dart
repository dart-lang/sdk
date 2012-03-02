
class _SVGAnimatedPreserveAspectRatioImpl extends _DOMTypeBase implements SVGAnimatedPreserveAspectRatio {
  _SVGAnimatedPreserveAspectRatioImpl._wrap(ptr) : super._wrap(ptr);

  SVGPreserveAspectRatio get animVal() => _wrap(_ptr.animVal);

  SVGPreserveAspectRatio get baseVal() => _wrap(_ptr.baseVal);
}
