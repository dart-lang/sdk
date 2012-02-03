
class _SVGFEGaussianBlurElementJs extends _SVGElementJs implements SVGFEGaussianBlurElement native "*SVGFEGaussianBlurElement" {

  _SVGAnimatedStringJs get in1() native "return this.in1;";

  _SVGAnimatedNumberJs get stdDeviationX() native "return this.stdDeviationX;";

  _SVGAnimatedNumberJs get stdDeviationY() native "return this.stdDeviationY;";

  void setStdDeviation(num stdDeviationX, num stdDeviationY) native;

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
