
class _DListElementImpl extends _ElementImpl implements DListElement {
  _DListElementImpl._wrap(ptr) : super._wrap(ptr);

  bool get compact() => _wrap(_ptr.compact);

  void set compact(bool value) { _ptr.compact = _unwrap(value); }
}
