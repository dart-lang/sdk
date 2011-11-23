
class SVGCursorElement extends SVGElement native "*SVGCursorElement" {

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGURIReference

  SVGAnimatedString href;

  // From SVGTests

  SVGStringList requiredExtensions;

  SVGStringList requiredFeatures;

  SVGStringList systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;
}
