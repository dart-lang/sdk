
class _SVGPreserveAspectRatioImpl extends _DOMTypeBase implements SVGPreserveAspectRatio {
  _SVGPreserveAspectRatioImpl._wrap(ptr) : super._wrap(ptr);

  int get align() => _wrap(_ptr.align);

  void set align(int value) { _ptr.align = _unwrap(value); }

  int get meetOrSlice() => _wrap(_ptr.meetOrSlice);

  void set meetOrSlice(int value) { _ptr.meetOrSlice = _unwrap(value); }
}
