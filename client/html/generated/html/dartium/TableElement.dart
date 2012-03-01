
class _TableElementImpl extends _ElementImpl implements TableElement {
  _TableElementImpl._wrap(ptr) : super._wrap(ptr);

  String get align() => _wrap(_ptr.align);

  void set align(String value) { _ptr.align = _unwrap(value); }

  String get bgColor() => _wrap(_ptr.bgColor);

  void set bgColor(String value) { _ptr.bgColor = _unwrap(value); }

  String get border() => _wrap(_ptr.border);

  void set border(String value) { _ptr.border = _unwrap(value); }

  TableCaptionElement get caption() => _wrap(_ptr.caption);

  void set caption(TableCaptionElement value) { _ptr.caption = _unwrap(value); }

  String get cellPadding() => _wrap(_ptr.cellPadding);

  void set cellPadding(String value) { _ptr.cellPadding = _unwrap(value); }

  String get cellSpacing() => _wrap(_ptr.cellSpacing);

  void set cellSpacing(String value) { _ptr.cellSpacing = _unwrap(value); }

  String get frame() => _wrap(_ptr.frame);

  void set frame(String value) { _ptr.frame = _unwrap(value); }

  HTMLCollection get rows() => _wrap(_ptr.rows);

  String get rules() => _wrap(_ptr.rules);

  void set rules(String value) { _ptr.rules = _unwrap(value); }

  String get summary() => _wrap(_ptr.summary);

  void set summary(String value) { _ptr.summary = _unwrap(value); }

  HTMLCollection get tBodies() => _wrap(_ptr.tBodies);

  TableSectionElement get tFoot() => _wrap(_ptr.tFoot);

  void set tFoot(TableSectionElement value) { _ptr.tFoot = _unwrap(value); }

  TableSectionElement get tHead() => _wrap(_ptr.tHead);

  void set tHead(TableSectionElement value) { _ptr.tHead = _unwrap(value); }

  String get width() => _wrap(_ptr.width);

  void set width(String value) { _ptr.width = _unwrap(value); }

  Element createCaption() {
    return _wrap(_ptr.createCaption());
  }

  Element createTFoot() {
    return _wrap(_ptr.createTFoot());
  }

  Element createTHead() {
    return _wrap(_ptr.createTHead());
  }

  void deleteCaption() {
    _ptr.deleteCaption();
    return;
  }

  void deleteRow(int index) {
    _ptr.deleteRow(_unwrap(index));
    return;
  }

  void deleteTFoot() {
    _ptr.deleteTFoot();
    return;
  }

  void deleteTHead() {
    _ptr.deleteTHead();
    return;
  }

  Element insertRow(int index) {
    return _wrap(_ptr.insertRow(_unwrap(index)));
  }
}
