
class _TableCaptionElementImpl extends _ElementImpl implements TableCaptionElement {
  _TableCaptionElementImpl._wrap(ptr) : super._wrap(ptr);

  String get align() => _wrap(_ptr.align);

  void set align(String value) { _ptr.align = _unwrap(value); }
}
