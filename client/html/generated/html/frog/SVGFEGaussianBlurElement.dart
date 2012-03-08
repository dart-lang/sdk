
class _SVGFEGaussianBlurElementImpl extends _SVGElementImpl implements SVGFEGaussianBlurElement native "*SVGFEGaussianBlurElement" {

  final _SVGAnimatedStringImpl in1;

  final _SVGAnimatedNumberImpl stdDeviationX;

  final _SVGAnimatedNumberImpl stdDeviationY;

  void setStdDeviation(num stdDeviationX, num stdDeviationY) native;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedStringImpl result;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  // From SVGStylable

  _SVGAnimatedStringImpl get _svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}
