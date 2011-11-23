
class SVGPatternElement extends SVGElement native "*SVGPatternElement" {

  SVGAnimatedLength height;

  SVGAnimatedEnumeration patternContentUnits;

  SVGAnimatedTransformList patternTransform;

  SVGAnimatedEnumeration patternUnits;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGURIReference

  SVGAnimatedString href;

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

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio preserveAspectRatio;

  SVGAnimatedRect viewBox;
}
