
class SVGFEDisplacementMapElement extends SVGElement native "SVGFEDisplacementMapElement" {

  SVGAnimatedString in1;

  SVGAnimatedString in2;

  SVGAnimatedNumber scale;

  SVGAnimatedEnumeration xChannelSelector;

  SVGAnimatedEnumeration yChannelSelector;

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
