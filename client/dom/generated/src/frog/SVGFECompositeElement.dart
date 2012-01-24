
class SVGFECompositeElementJs extends SVGElementJs implements SVGFECompositeElement native "*SVGFECompositeElement" {

  static final int SVG_FECOMPOSITE_OPERATOR_ARITHMETIC = 6;

  static final int SVG_FECOMPOSITE_OPERATOR_ATOP = 4;

  static final int SVG_FECOMPOSITE_OPERATOR_IN = 2;

  static final int SVG_FECOMPOSITE_OPERATOR_OUT = 3;

  static final int SVG_FECOMPOSITE_OPERATOR_OVER = 1;

  static final int SVG_FECOMPOSITE_OPERATOR_UNKNOWN = 0;

  static final int SVG_FECOMPOSITE_OPERATOR_XOR = 5;

  SVGAnimatedStringJs get in1() native "return this.in1;";

  SVGAnimatedStringJs get in2() native "return this.in2;";

  SVGAnimatedNumberJs get k1() native "return this.k1;";

  SVGAnimatedNumberJs get k2() native "return this.k2;";

  SVGAnimatedNumberJs get k3() native "return this.k3;";

  SVGAnimatedNumberJs get k4() native "return this.k4;";

  SVGAnimatedEnumerationJs get operator() native "return this.operator;";

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
