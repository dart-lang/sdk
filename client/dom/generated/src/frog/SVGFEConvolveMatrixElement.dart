
class SVGFEConvolveMatrixElement extends SVGElement native "*SVGFEConvolveMatrixElement" {

  static final int SVG_EDGEMODE_DUPLICATE = 1;

  static final int SVG_EDGEMODE_NONE = 3;

  static final int SVG_EDGEMODE_UNKNOWN = 0;

  static final int SVG_EDGEMODE_WRAP = 2;

  SVGAnimatedNumber bias;

  SVGAnimatedNumber divisor;

  SVGAnimatedEnumeration edgeMode;

  SVGAnimatedString in1;

  SVGAnimatedNumberList kernelMatrix;

  SVGAnimatedNumber kernelUnitLengthX;

  SVGAnimatedNumber kernelUnitLengthY;

  SVGAnimatedInteger orderX;

  SVGAnimatedInteger orderY;

  SVGAnimatedBoolean preserveAlpha;

  SVGAnimatedInteger targetX;

  SVGAnimatedInteger targetY;

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength height;

  SVGAnimatedString result;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}
