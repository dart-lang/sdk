
class _MapElementImpl extends _ElementImpl implements MapElement {
  _MapElementImpl._wrap(ptr) : super._wrap(ptr);

  HTMLCollection get areas() => _wrap(_ptr.areas);

  String get name() => _wrap(_ptr.name);

  void set name(String value) { _ptr.name = _unwrap(value); }
}
