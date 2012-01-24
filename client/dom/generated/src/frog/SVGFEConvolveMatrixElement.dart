
class SVGFEConvolveMatrixElementJs extends SVGElementJs implements SVGFEConvolveMatrixElement native "*SVGFEConvolveMatrixElement" {

  static final int SVG_EDGEMODE_DUPLICATE = 1;

  static final int SVG_EDGEMODE_NONE = 3;

  static final int SVG_EDGEMODE_UNKNOWN = 0;

  static final int SVG_EDGEMODE_WRAP = 2;

  SVGAnimatedNumberJs get bias() native "return this.bias;";

  SVGAnimatedNumberJs get divisor() native "return this.divisor;";

  SVGAnimatedEnumerationJs get edgeMode() native "return this.edgeMode;";

  SVGAnimatedStringJs get in1() native "return this.in1;";

  SVGAnimatedNumberListJs get kernelMatrix() native "return this.kernelMatrix;";

  SVGAnimatedNumberJs get kernelUnitLengthX() native "return this.kernelUnitLengthX;";

  SVGAnimatedNumberJs get kernelUnitLengthY() native "return this.kernelUnitLengthY;";

  SVGAnimatedIntegerJs get orderX() native "return this.orderX;";

  SVGAnimatedIntegerJs get orderY() native "return this.orderY;";

  SVGAnimatedBooleanJs get preserveAlpha() native "return this.preserveAlpha;";

  SVGAnimatedIntegerJs get targetX() native "return this.targetX;";

  SVGAnimatedIntegerJs get targetY() native "return this.targetY;";

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
