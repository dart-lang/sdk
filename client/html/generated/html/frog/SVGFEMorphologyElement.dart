
class _SVGFEMorphologyElementImpl extends _SVGElementImpl implements SVGFEMorphologyElement native "*SVGFEMorphologyElement" {

  static final int SVG_MORPHOLOGY_OPERATOR_DILATE = 2;

  static final int SVG_MORPHOLOGY_OPERATOR_ERODE = 1;

  static final int SVG_MORPHOLOGY_OPERATOR_UNKNOWN = 0;

  final _SVGAnimatedStringImpl in1;

  final _SVGAnimatedEnumerationImpl operator;

  final _SVGAnimatedNumberImpl radiusX;

  final _SVGAnimatedNumberImpl radiusY;

  void setRadius(num radiusX, num radiusY) native;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedStringImpl result;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  // From SVGStylable

  _SVGAnimatedStringImpl get _svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}
