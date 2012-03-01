
class _SVGAnimatedStringImpl extends _DOMTypeBase implements SVGAnimatedString {
  _SVGAnimatedStringImpl._wrap(ptr) : super._wrap(ptr);

  String get animVal() => _wrap(_ptr.animVal);

  String get baseVal() => _wrap(_ptr.baseVal);

  void set baseVal(String value) { _ptr.baseVal = _unwrap(value); }
}
