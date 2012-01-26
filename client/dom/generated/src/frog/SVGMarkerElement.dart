
class SVGMarkerElementJs extends SVGElementJs implements SVGMarkerElement native "*SVGMarkerElement" {

  static final int SVG_MARKERUNITS_STROKEWIDTH = 2;

  static final int SVG_MARKERUNITS_UNKNOWN = 0;

  static final int SVG_MARKERUNITS_USERSPACEONUSE = 1;

  static final int SVG_MARKER_ORIENT_ANGLE = 2;

  static final int SVG_MARKER_ORIENT_AUTO = 1;

  static final int SVG_MARKER_ORIENT_UNKNOWN = 0;

  SVGAnimatedLengthJs get markerHeight() native "return this.markerHeight;";

  SVGAnimatedEnumerationJs get markerUnits() native "return this.markerUnits;";

  SVGAnimatedLengthJs get markerWidth() native "return this.markerWidth;";

  SVGAnimatedAngleJs get orientAngle() native "return this.orientAngle;";

  SVGAnimatedEnumerationJs get orientType() native "return this.orientType;";

  SVGAnimatedLengthJs get refX() native "return this.refX;";

  SVGAnimatedLengthJs get refY() native "return this.refY;";

  void setOrientToAngle(SVGAngleJs angle) native;

  void setOrientToAuto() native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBooleanJs get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedStringJs get className() native "return this.className;";

  CSSStyleDeclarationJs get style() native "return this.style;";

  CSSValueJs getPresentationAttribute(String name) native;

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatioJs get preserveAspectRatio() native "return this.preserveAspectRatio;";

  SVGAnimatedRectJs get viewBox() native "return this.viewBox;";
}
