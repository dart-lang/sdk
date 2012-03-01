
class _SVGFEConvolveMatrixElementImpl extends _SVGElementImpl implements SVGFEConvolveMatrixElement native "*SVGFEConvolveMatrixElement" {

  static final int SVG_EDGEMODE_DUPLICATE = 1;

  static final int SVG_EDGEMODE_NONE = 3;

  static final int SVG_EDGEMODE_UNKNOWN = 0;

  static final int SVG_EDGEMODE_WRAP = 2;

  final _SVGAnimatedNumberImpl bias;

  final _SVGAnimatedNumberImpl divisor;

  final _SVGAnimatedEnumerationImpl edgeMode;

  final _SVGAnimatedStringImpl in1;

  final _SVGAnimatedNumberListImpl kernelMatrix;

  final _SVGAnimatedNumberImpl kernelUnitLengthX;

  final _SVGAnimatedNumberImpl kernelUnitLengthY;

  final _SVGAnimatedIntegerImpl orderX;

  final _SVGAnimatedIntegerImpl orderY;

  final _SVGAnimatedBooleanImpl preserveAlpha;

  final _SVGAnimatedIntegerImpl targetX;

  final _SVGAnimatedIntegerImpl targetY;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedStringImpl result;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  // From SVGStylable

  _SVGAnimatedStringImpl get _className() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}
