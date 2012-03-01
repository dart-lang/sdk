
class _SVGAnimatedBooleanImpl extends _DOMTypeBase implements SVGAnimatedBoolean {
  _SVGAnimatedBooleanImpl._wrap(ptr) : super._wrap(ptr);

  bool get animVal() => _wrap(_ptr.animVal);

  bool get baseVal() => _wrap(_ptr.baseVal);

  void set baseVal(bool value) { _ptr.baseVal = _unwrap(value); }
}
