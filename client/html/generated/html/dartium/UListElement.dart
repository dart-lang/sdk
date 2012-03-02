
class _UListElementImpl extends _ElementImpl implements UListElement {
  _UListElementImpl._wrap(ptr) : super._wrap(ptr);

  bool get compact() => _wrap(_ptr.compact);

  void set compact(bool value) { _ptr.compact = _unwrap(value); }

  String get type() => _wrap(_ptr.type);

  void set type(String value) { _ptr.type = _unwrap(value); }
}
