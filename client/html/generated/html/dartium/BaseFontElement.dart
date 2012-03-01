
class _BaseFontElementImpl extends _ElementImpl implements BaseFontElement {
  _BaseFontElementImpl._wrap(ptr) : super._wrap(ptr);

  String get color() => _wrap(_ptr.color);

  void set color(String value) { _ptr.color = _unwrap(value); }

  String get face() => _wrap(_ptr.face);

  void set face(String value) { _ptr.face = _unwrap(value); }

  int get size() => _wrap(_ptr.size);

  void set size(int value) { _ptr.size = _unwrap(value); }
}
