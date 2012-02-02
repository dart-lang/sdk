
class _SVGAnimationElementJs extends _SVGElementJs implements SVGAnimationElement native "*SVGAnimationElement" {

  _SVGElementJs get targetElement() native "return this.targetElement;";

  num getCurrentTime() native;

  num getSimpleDuration() native;

  num getStartTime() native;

  // From SVGTests

  _SVGStringListJs get requiredExtensions() native "return this.requiredExtensions;";

  _SVGStringListJs get requiredFeatures() native "return this.requiredFeatures;";

  _SVGStringListJs get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGExternalResourcesRequired

  _SVGAnimatedBooleanJs get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From ElementTimeControl

  void beginElement() native;

  void beginElementAt(num offset) native;

  void endElement() native;

  void endElementAt(num offset) native;
}
