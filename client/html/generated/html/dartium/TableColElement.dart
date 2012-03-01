
class _TableColElementImpl extends _ElementImpl implements TableColElement {
  _TableColElementImpl._wrap(ptr) : super._wrap(ptr);

  String get align() => _wrap(_ptr.align);

  void set align(String value) { _ptr.align = _unwrap(value); }

  String get ch() => _wrap(_ptr.ch);

  void set ch(String value) { _ptr.ch = _unwrap(value); }

  String get chOff() => _wrap(_ptr.chOff);

  void set chOff(String value) { _ptr.chOff = _unwrap(value); }

  int get span() => _wrap(_ptr.span);

  void set span(int value) { _ptr.span = _unwrap(value); }

  String get vAlign() => _wrap(_ptr.vAlign);

  void set vAlign(String value) { _ptr.vAlign = _unwrap(value); }

  String get width() => _wrap(_ptr.width);

  void set width(String value) { _ptr.width = _unwrap(value); }
}
