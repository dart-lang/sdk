
class SVGFESpecularLightingElement extends SVGElement native "*SVGFESpecularLightingElement" {

  SVGAnimatedString in1;

  SVGAnimatedNumber specularConstant;

  SVGAnimatedNumber specularExponent;

  SVGAnimatedNumber surfaceScale;

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
