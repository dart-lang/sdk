
class _DirectoryElementImpl extends _ElementImpl implements DirectoryElement {
  _DirectoryElementImpl._wrap(ptr) : super._wrap(ptr);

  bool get compact() => _wrap(_ptr.compact);

  void set compact(bool value) { _ptr.compact = _unwrap(value); }
}
