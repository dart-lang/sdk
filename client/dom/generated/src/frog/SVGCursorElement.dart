
class SVGCursorElement extends SVGElement native "*SVGCursorElement" {

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  // From SVGURIReference

  SVGAnimatedString get href() native "return this.href;";

  // From SVGTests

  SVGStringList get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringList get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringList get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";
}
