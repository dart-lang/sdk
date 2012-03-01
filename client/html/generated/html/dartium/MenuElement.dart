
class _MenuElementImpl extends _ElementImpl implements MenuElement {
  _MenuElementImpl._wrap(ptr) : super._wrap(ptr);

  bool get compact() => _wrap(_ptr.compact);

  void set compact(bool value) { _ptr.compact = _unwrap(value); }
}
