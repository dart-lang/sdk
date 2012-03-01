
class _SVGAnimatedEnumerationImpl extends _DOMTypeBase implements SVGAnimatedEnumeration {
  _SVGAnimatedEnumerationImpl._wrap(ptr) : super._wrap(ptr);

  int get animVal() => _wrap(_ptr.animVal);

  int get baseVal() => _wrap(_ptr.baseVal);

  void set baseVal(int value) { _ptr.baseVal = _unwrap(value); }
}
