
class _SVGFEConvolveMatrixElementJs extends _SVGElementJs implements SVGFEConvolveMatrixElement native "*SVGFEConvolveMatrixElement" {

  static final int SVG_EDGEMODE_DUPLICATE = 1;

  static final int SVG_EDGEMODE_NONE = 3;

  static final int SVG_EDGEMODE_UNKNOWN = 0;

  static final int SVG_EDGEMODE_WRAP = 2;

  _SVGAnimatedNumberJs get bias() native "return this.bias;";

  _SVGAnimatedNumberJs get divisor() native "return this.divisor;";

  _SVGAnimatedEnumerationJs get edgeMode() native "return this.edgeMode;";

  _SVGAnimatedStringJs get in1() native "return this.in1;";

  _SVGAnimatedNumberListJs get kernelMatrix() native "return this.kernelMatrix;";

  _SVGAnimatedNumberJs get kernelUnitLengthX() native "return this.kernelUnitLengthX;";

  _SVGAnimatedNumberJs get kernelUnitLengthY() native "return this.kernelUnitLengthY;";

  _SVGAnimatedIntegerJs get orderX() native "return this.orderX;";

  _SVGAnimatedIntegerJs get orderY() native "return this.orderY;";

  _SVGAnimatedBooleanJs get preserveAlpha() native "return this.preserveAlpha;";

  _SVGAnimatedIntegerJs get targetX() native "return this.targetX;";

  _SVGAnimatedIntegerJs get targetY() native "return this.targetY;";

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
