
class _AttrImpl extends _NodeImpl implements Attr {
  _AttrImpl._wrap(ptr) : super._wrap(ptr);

  bool get isId() => _wrap(_ptr.isId);

  String get name() => _wrap(_ptr.name);

  Element get ownerElement() => _wrap(_ptr.ownerElement);

  bool get specified() => _wrap(_ptr.specified);

  String get value() => _wrap(_ptr.value);

  void set value(String value) { _ptr.value = _unwrap(value); }
}
