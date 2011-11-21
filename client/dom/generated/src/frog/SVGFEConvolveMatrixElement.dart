
class SVGFEConvolveMatrixElement extends SVGElement native "SVGFEConvolveMatrixElement" {

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
