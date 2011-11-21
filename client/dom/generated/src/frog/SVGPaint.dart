
class SVGPaint extends SVGColor native "SVGPaint" {

  int paintType;

  String uri;

  void setPaint(int paintType, String uri, String rgbColor, String iccColor) native;

  void setUri(String uri) native;
}
