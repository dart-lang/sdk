
class _DetailsElementImpl extends _ElementImpl implements DetailsElement {
  _DetailsElementImpl._wrap(ptr) : super._wrap(ptr);

  bool get open() => _wrap(_ptr.open);

  void set open(bool value) { _ptr.open = _unwrap(value); }
}
