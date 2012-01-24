
class SVGMarkerElementJS extends SVGElementJS implements SVGMarkerElement native "*SVGMarkerElement" {

  static final int SVG_MARKERUNITS_STROKEWIDTH = 2;

  static final int SVG_MARKERUNITS_UNKNOWN = 0;

  static final int SVG_MARKERUNITS_USERSPACEONUSE = 1;

  static final int SVG_MARKER_ORIENT_ANGLE = 2;

  static final int SVG_MARKER_ORIENT_AUTO = 1;

  static final int SVG_MARKER_ORIENT_UNKNOWN = 0;

  SVGAnimatedLengthJS get markerHeight() native "return this.markerHeight;";

  SVGAnimatedEnumerationJS get markerUnits() native "return this.markerUnits;";

  SVGAnimatedLengthJS get markerWidth() native "return this.markerWidth;";

  SVGAnimatedAngleJS get orientAngle() native "return this.orientAngle;";

  SVGAnimatedEnumerationJS get orientType() native "return this.orientType;";

  SVGAnimatedLengthJS get refX() native "return this.refX;";

  SVGAnimatedLengthJS get refY() native "return this.refY;";

  void setOrientToAngle(SVGAngleJS angle) native;

  void setOrientToAuto() native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBooleanJS get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedStringJS get className() native "return this.className;";

  CSSStyleDeclarationJS get style() native "return this.style;";

  CSSValueJS getPresentationAttribute(String name) native;

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatioJS get preserveAspectRatio() native "return this.preserveAspectRatio;";

  SVGAnimatedRectJS get viewBox() native "return this.viewBox;";
}
