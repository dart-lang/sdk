
class SVGMarkerElement extends SVGElement native "*SVGMarkerElement" {

  static final int SVG_MARKERUNITS_STROKEWIDTH = 2;

  static final int SVG_MARKERUNITS_UNKNOWN = 0;

  static final int SVG_MARKERUNITS_USERSPACEONUSE = 1;

  static final int SVG_MARKER_ORIENT_ANGLE = 2;

  static final int SVG_MARKER_ORIENT_AUTO = 1;

  static final int SVG_MARKER_ORIENT_UNKNOWN = 0;

  SVGAnimatedLength get markerHeight() native "return this.markerHeight;";

  SVGAnimatedEnumeration get markerUnits() native "return this.markerUnits;";

  SVGAnimatedLength get markerWidth() native "return this.markerWidth;";

  SVGAnimatedAngle get orientAngle() native "return this.orientAngle;";

  SVGAnimatedEnumeration get orientType() native "return this.orientType;";

  SVGAnimatedLength get refX() native "return this.refX;";

  SVGAnimatedLength get refY() native "return this.refY;";

  void setOrientToAngle(SVGAngle angle) native;

  void setOrientToAuto() native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() native "return this.preserveAspectRatio;";

  SVGAnimatedRect get viewBox() native "return this.viewBox;";
}
