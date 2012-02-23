
class _SVGFEConvolveMatrixElementJs extends _SVGElementJs implements SVGFEConvolveMatrixElement native "*SVGFEConvolveMatrixElement" {

  static final int SVG_EDGEMODE_DUPLICATE = 1;

  static final int SVG_EDGEMODE_NONE = 3;

  static final int SVG_EDGEMODE_UNKNOWN = 0;

  static final int SVG_EDGEMODE_WRAP = 2;

  final _SVGAnimatedNumberJs bias;

  final _SVGAnimatedNumberJs divisor;

  final _SVGAnimatedEnumerationJs edgeMode;

  final _SVGAnimatedStringJs in1;

  final _SVGAnimatedNumberListJs kernelMatrix;

  final _SVGAnimatedNumberJs kernelUnitLengthX;

  final _SVGAnimatedNumberJs kernelUnitLengthY;

  final _SVGAnimatedIntegerJs orderX;

  final _SVGAnimatedIntegerJs orderY;

  final _SVGAnimatedBooleanJs preserveAlpha;

  final _SVGAnimatedIntegerJs targetX;

  final _SVGAnimatedIntegerJs targetY;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthJs height;

  final _SVGAnimatedStringJs result;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  // Use implementation from Element.
  // final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;
}
