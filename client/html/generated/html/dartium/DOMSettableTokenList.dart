
class _DOMSettableTokenListImpl extends _DOMTokenListImpl implements DOMSettableTokenList {
  _DOMSettableTokenListImpl._wrap(ptr) : super._wrap(ptr);

  String get value() => _wrap(_ptr.value);

  void set value(String value) { _ptr.value = _unwrap(value); }
}
