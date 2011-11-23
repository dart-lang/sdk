
class SVGFECompositeElement extends SVGElement native "*SVGFECompositeElement" {

  SVGAnimatedString in1;

  SVGAnimatedString in2;

  SVGAnimatedNumber k1;

  SVGAnimatedNumber k2;

  SVGAnimatedNumber k3;

  SVGAnimatedNumber k4;

  SVGAnimatedEnumeration operator;

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
