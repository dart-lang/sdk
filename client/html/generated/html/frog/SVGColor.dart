
class _SVGColorImpl extends _CSSValueImpl implements SVGColor native "*SVGColor" {

  static final int SVG_COLORTYPE_CURRENTCOLOR = 3;

  static final int SVG_COLORTYPE_RGBCOLOR = 1;

  static final int SVG_COLORTYPE_RGBCOLOR_ICCCOLOR = 2;

  static final int SVG_COLORTYPE_UNKNOWN = 0;

  final int colorType;

  final _RGBColorImpl rgbColor;

  void setColor(int colorType, String rgbColor, String iccColor) native;

  void setRGBColor(String rgbColor) native;

  void setRGBColorICCColor(String rgbColor, String iccColor) native;
}
