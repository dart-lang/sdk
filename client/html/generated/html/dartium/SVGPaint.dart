
class _SVGPaintImpl extends _SVGColorImpl implements SVGPaint {
  _SVGPaintImpl._wrap(ptr) : super._wrap(ptr);

  int get paintType() => _wrap(_ptr.paintType);

  String get uri() => _wrap(_ptr.uri);

  void setPaint(int paintType, String uri, String rgbColor, String iccColor) {
    _ptr.setPaint(_unwrap(paintType), _unwrap(uri), _unwrap(rgbColor), _unwrap(iccColor));
    return;
  }

  void setUri(String uri) {
    _ptr.setUri(_unwrap(uri));
    return;
  }
}
