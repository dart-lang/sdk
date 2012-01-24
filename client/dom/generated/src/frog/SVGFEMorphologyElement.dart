
class SVGFEMorphologyElementJs extends SVGElementJs implements SVGFEMorphologyElement native "*SVGFEMorphologyElement" {

  static final int SVG_MORPHOLOGY_OPERATOR_DILATE = 2;

  static final int SVG_MORPHOLOGY_OPERATOR_ERODE = 1;

  static final int SVG_MORPHOLOGY_OPERATOR_UNKNOWN = 0;

  SVGAnimatedStringJs get in1() native "return this.in1;";

  SVGAnimatedEnumerationJs get operator() native "return this.operator;";

  SVGAnimatedNumberJs get radiusX() native "return this.radiusX;";

  SVGAnimatedNumberJs get radiusY() native "return this.radiusY;";

  void setRadius(num radiusX, num radiusY) native;

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLengthJs get height() native "return this.height;";

  SVGAnimatedStringJs get result() native "return this.result;";

  SVGAnimatedLengthJs get width() native "return this.width;";

  SVGAnimatedLengthJs get x() native "return this.x;";

  SVGAnimatedLengthJs get y() native "return this.y;";

  // From SVGStylable

  SVGAnimatedStringJs get className() native "return this.className;";

  CSSStyleDeclarationJs get style() native "return this.style;";

  CSSValueJs getPresentationAttribute(String name) native;
}
