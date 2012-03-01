
class _HeadingElementImpl extends _ElementImpl implements HeadingElement {
  _HeadingElementImpl._wrap(ptr) : super._wrap(ptr);

  String get align() => _wrap(_ptr.align);

  void set align(String value) { _ptr.align = _unwrap(value); }
}
