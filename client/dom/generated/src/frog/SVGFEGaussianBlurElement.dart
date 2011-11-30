
class SVGFEGaussianBlurElement extends SVGElement native "*SVGFEGaussianBlurElement" {

  SVGAnimatedString in1;

  SVGAnimatedNumber stdDeviationX;

  SVGAnimatedNumber stdDeviationY;

  void setStdDeviation(num stdDeviationX, num stdDeviationY) native;

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
