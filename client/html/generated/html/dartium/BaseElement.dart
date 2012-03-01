
class _BaseElementImpl extends _ElementImpl implements BaseElement {
  _BaseElementImpl._wrap(ptr) : super._wrap(ptr);

  String get href() => _wrap(_ptr.href);

  void set href(String value) { _ptr.href = _unwrap(value); }

  String get target() => _wrap(_ptr.target);

  void set target(String value) { _ptr.target = _unwrap(value); }
}
