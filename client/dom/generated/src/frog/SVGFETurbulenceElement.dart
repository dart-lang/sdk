
class SVGFETurbulenceElement extends SVGElement native "*SVGFETurbulenceElement" {

  SVGAnimatedNumber baseFrequencyX;

  SVGAnimatedNumber baseFrequencyY;

  SVGAnimatedInteger numOctaves;

  SVGAnimatedNumber seed;

  SVGAnimatedEnumeration stitchTiles;

  SVGAnimatedEnumeration type;

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
