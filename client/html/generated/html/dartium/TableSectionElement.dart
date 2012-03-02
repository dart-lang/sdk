
class _TableSectionElementImpl extends _ElementImpl implements TableSectionElement {
  _TableSectionElementImpl._wrap(ptr) : super._wrap(ptr);

  String get align() => _wrap(_ptr.align);

  void set align(String value) { _ptr.align = _unwrap(value); }

  String get ch() => _wrap(_ptr.ch);

  void set ch(String value) { _ptr.ch = _unwrap(value); }

  String get chOff() => _wrap(_ptr.chOff);

  void set chOff(String value) { _ptr.chOff = _unwrap(value); }

  HTMLCollection get rows() => _wrap(_ptr.rows);

  String get vAlign() => _wrap(_ptr.vAlign);

  void set vAlign(String value) { _ptr.vAlign = _unwrap(value); }

  void deleteRow(int index) {
    _ptr.deleteRow(_unwrap(index));
    return;
  }

  Element insertRow(int index) {
    return _wrap(_ptr.insertRow(_unwrap(index)));
  }
}
