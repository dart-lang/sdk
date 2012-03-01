
class _SVGAnimatedRectImpl extends _DOMTypeBase implements SVGAnimatedRect {
  _SVGAnimatedRectImpl._wrap(ptr) : super._wrap(ptr);

  SVGRect get animVal() => _wrap(_ptr.animVal);

  SVGRect get baseVal() => _wrap(_ptr.baseVal);
}
