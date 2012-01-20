
class SVGFEConvolveMatrixElement extends SVGElement native "*SVGFEConvolveMatrixElement" {

  static final int SVG_EDGEMODE_DUPLICATE = 1;

  static final int SVG_EDGEMODE_NONE = 3;

  static final int SVG_EDGEMODE_UNKNOWN = 0;

  static final int SVG_EDGEMODE_WRAP = 2;

  SVGAnimatedNumber get bias() native "return this.bias;";

  SVGAnimatedNumber get divisor() native "return this.divisor;";

  SVGAnimatedEnumeration get edgeMode() native "return this.edgeMode;";

  SVGAnimatedString get in1() native "return this.in1;";

  SVGAnimatedNumberList get kernelMatrix() native "return this.kernelMatrix;";

  SVGAnimatedNumber get kernelUnitLengthX() native "return this.kernelUnitLengthX;";

  SVGAnimatedNumber get kernelUnitLengthY() native "return this.kernelUnitLengthY;";

  SVGAnimatedInteger get orderX() native "return this.orderX;";

  SVGAnimatedInteger get orderY() native "return this.orderY;";

  SVGAnimatedBoolean get preserveAlpha() native "return this.preserveAlpha;";

  SVGAnimatedInteger get targetX() native "return this.targetX;";

  SVGAnimatedInteger get targetY() native "return this.targetY;";

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() native "return this.height;";

  SVGAnimatedString get result() native "return this.result;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;
}
