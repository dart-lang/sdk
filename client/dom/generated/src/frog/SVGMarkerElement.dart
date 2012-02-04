
class _SVGMarkerElementJs extends _SVGElementJs implements SVGMarkerElement native "*SVGMarkerElement" {

  static final int SVG_MARKERUNITS_STROKEWIDTH = 2;

  static final int SVG_MARKERUNITS_UNKNOWN = 0;

  static final int SVG_MARKERUNITS_USERSPACEONUSE = 1;

  static final int SVG_MARKER_ORIENT_ANGLE = 2;

  static final int SVG_MARKER_ORIENT_AUTO = 1;

  static final int SVG_MARKER_ORIENT_UNKNOWN = 0;

  final _SVGAnimatedLengthJs markerHeight;

  final _SVGAnimatedEnumerationJs markerUnits;

  final _SVGAnimatedLengthJs markerWidth;

  final _SVGAnimatedAngleJs orientAngle;

  final _SVGAnimatedEnumerationJs orientType;

  final _SVGAnimatedLengthJs refX;

  final _SVGAnimatedLengthJs refY;

  void setOrientToAngle(_SVGAngleJs angle) native;

  void setOrientToAuto() native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;

  // From SVGFitToViewBox

  final _SVGAnimatedPreserveAspectRatioJs preserveAspectRatio;

  final _SVGAnimatedRectJs viewBox;
}
