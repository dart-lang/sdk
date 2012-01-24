
class SVGFEConvolveMatrixElementJS extends SVGElementJS implements SVGFEConvolveMatrixElement native "*SVGFEConvolveMatrixElement" {

  static final int SVG_EDGEMODE_DUPLICATE = 1;

  static final int SVG_EDGEMODE_NONE = 3;

  static final int SVG_EDGEMODE_UNKNOWN = 0;

  static final int SVG_EDGEMODE_WRAP = 2;

  SVGAnimatedNumberJS get bias() native "return this.bias;";

  SVGAnimatedNumberJS get divisor() native "return this.divisor;";

  SVGAnimatedEnumerationJS get edgeMode() native "return this.edgeMode;";

  SVGAnimatedStringJS get in1() native "return this.in1;";

  SVGAnimatedNumberListJS get kernelMatrix() native "return this.kernelMatrix;";

  SVGAnimatedNumberJS get kernelUnitLengthX() native "return this.kernelUnitLengthX;";

  SVGAnimatedNumberJS get kernelUnitLengthY() native "return this.kernelUnitLengthY;";

  SVGAnimatedIntegerJS get orderX() native "return this.orderX;";

  SVGAnimatedIntegerJS get orderY() native "return this.orderY;";

  SVGAnimatedBooleanJS get preserveAlpha() native "return this.preserveAlpha;";

  SVGAnimatedIntegerJS get targetX() native "return this.targetX;";

  SVGAnimatedIntegerJS get targetY() native "return this.targetY;";

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLengthJS get height() native "return this.height;";

  SVGAnimatedStringJS get result() native "return this.result;";

  SVGAnimatedLengthJS get width() native "return this.width;";

  SVGAnimatedLengthJS get x() native "return this.x;";

  SVGAnimatedLengthJS get y() native "return this.y;";

  // From SVGStylable

  SVGAnimatedStringJS get className() native "return this.className;";

  CSSStyleDeclarationJS get style() native "return this.style;";

  CSSValueJS getPresentationAttribute(String name) native;
}
