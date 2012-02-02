
class _SVGMarkerElementJs extends _SVGElementJs implements SVGMarkerElement native "*SVGMarkerElement" {

  static final int SVG_MARKERUNITS_STROKEWIDTH = 2;

  static final int SVG_MARKERUNITS_UNKNOWN = 0;

  static final int SVG_MARKERUNITS_USERSPACEONUSE = 1;

  static final int SVG_MARKER_ORIENT_ANGLE = 2;

  static final int SVG_MARKER_ORIENT_AUTO = 1;

  static final int SVG_MARKER_ORIENT_UNKNOWN = 0;

  _SVGAnimatedLengthJs get markerHeight() native "return this.markerHeight;";

  _SVGAnimatedEnumerationJs get markerUnits() native "return this.markerUnits;";

  _SVGAnimatedLengthJs get markerWidth() native "return this.markerWidth;";

  _SVGAnimatedAngleJs get orientAngle() native "return this.orientAngle;";

  _SVGAnimatedEnumerationJs get orientType() native "return this.orientType;";

  _SVGAnimatedLengthJs get refX() native "return this.refX;";

  _SVGAnimatedLengthJs get refY() native "return this.refY;";

  void setOrientToAngle(_SVGAngleJs angle) native;

  void setOrientToAuto() native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  _SVGAnimatedBooleanJs get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  _SVGAnimatedStringJs get className() native "return this.className;";

  _CSSStyleDeclarationJs get style() native "return this.style;";

  _CSSValueJs getPresentationAttribute(String name) native;

  // From SVGFitToViewBox

  _SVGAnimatedPreserveAspectRatioJs get preserveAspectRatio() native "return this.preserveAspectRatio;";

  _SVGAnimatedRectJs get viewBox() native "return this.viewBox;";
}
