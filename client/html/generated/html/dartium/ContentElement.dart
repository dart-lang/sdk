
class _ContentElementImpl extends _ElementImpl implements ContentElement {
  _ContentElementImpl._wrap(ptr) : super._wrap(ptr);

  String get select() => _wrap(_ptr.select);

  void set select(String value) { _ptr.select = _unwrap(value); }
}
