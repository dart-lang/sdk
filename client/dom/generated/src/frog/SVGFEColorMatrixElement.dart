
class SVGFEColorMatrixElement extends SVGElement native "SVGFEColorMatrixElement" {

  SVGAnimatedString in1;

  SVGAnimatedEnumeration type;

  SVGAnimatedNumberList values;

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
