
class _DivElementImpl extends _ElementImpl implements DivElement {
  _DivElementImpl._wrap(ptr) : super._wrap(ptr);

  String get align() => _wrap(_ptr.align);

  void set align(String value) { _ptr.align = _unwrap(value); }
}
