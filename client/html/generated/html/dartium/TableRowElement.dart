
class _TableRowElementImpl extends _ElementImpl implements TableRowElement {
  _TableRowElementImpl._wrap(ptr) : super._wrap(ptr);

  String get align() => _wrap(_ptr.align);

  void set align(String value) { _ptr.align = _unwrap(value); }

  String get bgColor() => _wrap(_ptr.bgColor);

  void set bgColor(String value) { _ptr.bgColor = _unwrap(value); }

  HTMLCollection get cells() => _wrap(_ptr.cells);

  String get ch() => _wrap(_ptr.ch);

  void set ch(String value) { _ptr.ch = _unwrap(value); }

  String get chOff() => _wrap(_ptr.chOff);

  void set chOff(String value) { _ptr.chOff = _unwrap(value); }

  int get rowIndex() => _wrap(_ptr.rowIndex);

  int get sectionRowIndex() => _wrap(_ptr.sectionRowIndex);

  String get vAlign() => _wrap(_ptr.vAlign);

  void set vAlign(String value) { _ptr.vAlign = _unwrap(value); }

  void deleteCell(int index) {
    _ptr.deleteCell(_unwrap(index));
    return;
  }

  Element insertCell(int index) {
    return _wrap(_ptr.insertCell(_unwrap(index)));
  }
}
