
class _SVGFEMorphologyElementJs extends _SVGElementJs implements SVGFEMorphologyElement native "*SVGFEMorphologyElement" {

  static final int SVG_MORPHOLOGY_OPERATOR_DILATE = 2;

  static final int SVG_MORPHOLOGY_OPERATOR_ERODE = 1;

  static final int SVG_MORPHOLOGY_OPERATOR_UNKNOWN = 0;

  _SVGAnimatedStringJs get in1() native "return this.in1;";

  _SVGAnimatedEnumerationJs get operator() native "return this.operator;";

  _SVGAnimatedNumberJs get radiusX() native "return this.radiusX;";

  _SVGAnimatedNumberJs get radiusY() native "return this.radiusY;";

  void setRadius(num radiusX, num radiusY) native;

  // From SVGFilterPrimitiveStandardAttributes

  _SVGAnimatedLengthJs get height() native "return this.height;";

  _SVGAnimatedStringJs get result() native "return this.result;";

  _SVGAnimatedLengthJs get width() native "return this.width;";

  _SVGAnimatedLengthJs get x() native "return this.x;";

  _SVGAnimatedLengthJs get y() native "return this.y;";

  // From SVGStylable

  _SVGAnimatedStringJs get className() native "return this.className;";

  _CSSStyleDeclarationJs get style() native "return this.style;";

  _CSSValueJs getPresentationAttribute(String name) native;
}
