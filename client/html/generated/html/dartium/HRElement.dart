
class _HRElementImpl extends _ElementImpl implements HRElement {
  _HRElementImpl._wrap(ptr) : super._wrap(ptr);

  String get align() => _wrap(_ptr.align);

  void set align(String value) { _ptr.align = _unwrap(value); }

  bool get noShade() => _wrap(_ptr.noShade);

  void set noShade(bool value) { _ptr.noShade = _unwrap(value); }

  String get size() => _wrap(_ptr.size);

  void set size(String value) { _ptr.size = _unwrap(value); }

  String get width() => _wrap(_ptr.width);

  void set width(String value) { _ptr.width = _unwrap(value); }
}
