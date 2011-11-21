
class SVGMarkerElement extends SVGElement native "SVGMarkerElement" {

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
