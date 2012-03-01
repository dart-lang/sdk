
class _BRElementImpl extends _ElementImpl implements BRElement {
  _BRElementImpl._wrap(ptr) : super._wrap(ptr);

  String get clear() => _wrap(_ptr.clear);

  void set clear(String value) { _ptr.clear = _unwrap(value); }
}
