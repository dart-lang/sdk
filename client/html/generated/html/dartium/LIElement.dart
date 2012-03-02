
class _LIElementImpl extends _ElementImpl implements LIElement {
  _LIElementImpl._wrap(ptr) : super._wrap(ptr);

  String get type() => _wrap(_ptr.type);

  void set type(String value) { _ptr.type = _unwrap(value); }

  int get value() => _wrap(_ptr.value);

  void set value(int value) { _ptr.value = _unwrap(value); }
}
