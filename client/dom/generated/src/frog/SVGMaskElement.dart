
class SVGMaskElement extends SVGElement native "SVGMaskElement" {

  SVGAnimatedLength height;

  SVGAnimatedEnumeration maskContentUnits;

  SVGAnimatedEnumeration maskUnits;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGTests

  SVGStringList requiredExtensions;

  SVGStringList requiredFeatures;

  SVGStringList systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}
