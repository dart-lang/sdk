
class SVGMarkerElement extends SVGElement native "*SVGMarkerElement" {

  static final int SVG_MARKERUNITS_STROKEWIDTH = 2;

  static final int SVG_MARKERUNITS_UNKNOWN = 0;

  static final int SVG_MARKERUNITS_USERSPACEONUSE = 1;

  static final int SVG_MARKER_ORIENT_ANGLE = 2;

  static final int SVG_MARKER_ORIENT_AUTO = 1;

  static final int SVG_MARKER_ORIENT_UNKNOWN = 0;

  SVGAnimatedLength markerHeight;

  SVGAnimatedEnumeration markerUnits;

  SVGAnimatedLength markerWidth;

  SVGAnimatedAngle orientAngle;

  SVGAnimatedEnumeration orientType;

  SVGAnimatedLength refX;

  SVGAnimatedLength refY;

  void setOrientToAngle(SVGAngle angle) native;

  void setOrientToAuto() native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio preserveAspectRatio;

  SVGAnimatedRect viewBox;
}
