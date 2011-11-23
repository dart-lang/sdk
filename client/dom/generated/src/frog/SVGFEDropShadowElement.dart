
class SVGFEDropShadowElement extends SVGElement native "*SVGFEDropShadowElement" {

  SVGAnimatedNumber dx;

  SVGAnimatedNumber dy;

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
