
class _PreElementImpl extends _ElementImpl implements PreElement {
  _PreElementImpl._wrap(ptr) : super._wrap(ptr);

  int get width() => _wrap(_ptr.width);

  void set width(int value) { _ptr.width = _unwrap(value); }

  bool get wrap() => _wrap(_ptr.wrap);

  void set wrap(bool value) { _ptr.wrap = _unwrap(value); }
}
