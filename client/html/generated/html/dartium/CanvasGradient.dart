
class _CanvasGradientImpl extends _DOMTypeBase implements CanvasGradient {
  _CanvasGradientImpl._wrap(ptr) : super._wrap(ptr);

  void addColorStop(num offset, String color) {
    _ptr.addColorStop(_unwrap(offset), _unwrap(color));
    return;
  }
}
