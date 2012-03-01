
class _SVGZoomAndPanImpl extends _DOMTypeBase implements SVGZoomAndPan {
  _SVGZoomAndPanImpl._wrap(ptr) : super._wrap(ptr);

  int get zoomAndPan() => _wrap(_ptr.zoomAndPan);

  void set zoomAndPan(int value) { _ptr.zoomAndPan = _unwrap(value); }
}
