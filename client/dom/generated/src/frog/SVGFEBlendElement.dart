
class SVGFEBlendElement extends SVGElement native "*SVGFEBlendElement" {

  SVGAnimatedString in1;

  SVGAnimatedString in2;

  SVGAnimatedEnumeration mode;

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
