
class _SVGNumberImpl extends _DOMTypeBase implements SVGNumber {
  _SVGNumberImpl._wrap(ptr) : super._wrap(ptr);

  num get value() => _wrap(_ptr.value);

  void set value(num value) { _ptr.value = _unwrap(value); }
}
