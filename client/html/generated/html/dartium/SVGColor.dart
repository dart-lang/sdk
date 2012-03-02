
class _SVGColorImpl extends _CSSValueImpl implements SVGColor {
  _SVGColorImpl._wrap(ptr) : super._wrap(ptr);

  int get colorType() => _wrap(_ptr.colorType);

  RGBColor get rgbColor() => _wrap(_ptr.rgbColor);

  void setColor(int colorType, String rgbColor, String iccColor) {
    _ptr.setColor(_unwrap(colorType), _unwrap(rgbColor), _unwrap(iccColor));
    return;
  }

  void setRGBColor(String rgbColor) {
    _ptr.setRGBColor(_unwrap(rgbColor));
    return;
  }

  void setRGBColorICCColor(String rgbColor, String iccColor) {
    _ptr.setRGBColorICCColor(_unwrap(rgbColor), _unwrap(iccColor));
    return;
  }
}
