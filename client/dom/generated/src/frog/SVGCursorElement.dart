
class SVGCursorElementJs extends SVGElementJs implements SVGCursorElement native "*SVGCursorElement" {

  SVGAnimatedLengthJs get x() native "return this.x;";

  SVGAnimatedLengthJs get y() native "return this.y;";

  // From SVGURIReference

  SVGAnimatedStringJs get href() native "return this.href;";

  // From SVGTests

  SVGStringListJs get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringListJs get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringListJs get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGExternalResourcesRequired

  SVGAnimatedBooleanJs get externalResourcesRequired() native "return this.externalResourcesRequired;";
}
