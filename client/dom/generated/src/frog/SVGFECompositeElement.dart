
class _SVGFECompositeElementJs extends _SVGElementJs implements SVGFECompositeElement native "*SVGFECompositeElement" {

  static final int SVG_FECOMPOSITE_OPERATOR_ARITHMETIC = 6;

  static final int SVG_FECOMPOSITE_OPERATOR_ATOP = 4;

  static final int SVG_FECOMPOSITE_OPERATOR_IN = 2;

  static final int SVG_FECOMPOSITE_OPERATOR_OUT = 3;

  static final int SVG_FECOMPOSITE_OPERATOR_OVER = 1;

  static final int SVG_FECOMPOSITE_OPERATOR_UNKNOWN = 0;

  static final int SVG_FECOMPOSITE_OPERATOR_XOR = 5;

  _SVGAnimatedStringJs get in1() native "return this.in1;";

  _SVGAnimatedStringJs get in2() native "return this.in2;";

  _SVGAnimatedNumberJs get k1() native "return this.k1;";

  _SVGAnimatedNumberJs get k2() native "return this.k2;";

  _SVGAnimatedNumberJs get k3() native "return this.k3;";

  _SVGAnimatedNumberJs get k4() native "return this.k4;";

  _SVGAnimatedEnumerationJs get operator() native "return this.operator;";

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
