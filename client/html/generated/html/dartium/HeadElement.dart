
class _HeadElementImpl extends _ElementImpl implements HeadElement {
  _HeadElementImpl._wrap(ptr) : super._wrap(ptr);

  String get profile() => _wrap(_ptr.profile);

  void set profile(String value) { _ptr.profile = _unwrap(value); }
}
