
class _SVGMarkerElementImpl extends _SVGElementImpl implements SVGMarkerElement native "*SVGMarkerElement" {

  static final int SVG_MARKERUNITS_STROKEWIDTH = 2;

  static final int SVG_MARKERUNITS_UNKNOWN = 0;

  static final int SVG_MARKERUNITS_USERSPACEONUSE = 1;

  static final int SVG_MARKER_ORIENT_ANGLE = 2;

  static final int SVG_MARKER_ORIENT_AUTO = 1;

  static final int SVG_MARKER_ORIENT_UNKNOWN = 0;

  final _SVGAnimatedLengthImpl markerHeight;

  final _SVGAnimatedEnumerationImpl markerUnits;

  final _SVGAnimatedLengthImpl markerWidth;

  final _SVGAnimatedAngleImpl orientAngle;

  final _SVGAnimatedEnumerationImpl orientType;

  final _SVGAnimatedLengthImpl refX;

  final _SVGAnimatedLengthImpl refY;

  void setOrientToAngle(_SVGAngleImpl angle) native;

  void setOrientToAuto() native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From SVGStylable

  _SVGAnimatedStringImpl get _svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;

  // From SVGFitToViewBox

  final _SVGAnimatedPreserveAspectRatioImpl preserveAspectRatio;

  final _SVGAnimatedRectImpl viewBox;
}
