
class SVGColor extends CSSValue native "*SVGColor" {

  int colorType;

  RGBColor rgbColor;

  void setColor(int colorType, String rgbColor, String iccColor) native;

  void setRGBColor(String rgbColor) native;

  void setRGBColorICCColor(String rgbColor, String iccColor) native;
}
