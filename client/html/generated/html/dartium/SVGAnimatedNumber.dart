
class _SVGAnimatedNumberImpl extends _DOMTypeBase implements SVGAnimatedNumber {
  _SVGAnimatedNumberImpl._wrap(ptr) : super._wrap(ptr);

  num get animVal() => _wrap(_ptr.animVal);

  num get baseVal() => _wrap(_ptr.baseVal);

  void set baseVal(num value) { _ptr.baseVal = _unwrap(value); }
}
