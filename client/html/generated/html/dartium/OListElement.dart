
class _OListElementImpl extends _ElementImpl implements OListElement {
  _OListElementImpl._wrap(ptr) : super._wrap(ptr);

  bool get compact() => _wrap(_ptr.compact);

  void set compact(bool value) { _ptr.compact = _unwrap(value); }

  bool get reversed() => _wrap(_ptr.reversed);

  void set reversed(bool value) { _ptr.reversed = _unwrap(value); }

  int get start() => _wrap(_ptr.start);

  void set start(int value) { _ptr.start = _unwrap(value); }

  String get type() => _wrap(_ptr.type);

  void set type(String value) { _ptr.type = _unwrap(value); }
}
