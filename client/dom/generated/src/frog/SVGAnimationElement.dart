
class SVGAnimationElement extends SVGElement native "SVGAnimationElement" {

  SVGElement targetElement;

  num getCurrentTime() native;

  num getSimpleDuration() native;

  num getStartTime() native;

  // From SVGTests

  SVGStringList requiredExtensions;

  SVGStringList requiredFeatures;

  SVGStringList systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From ElementTimeControl

  void beginElement() native;

  void beginElementAt(num offset) native;

  void endElement() native;

  void endElementAt(num offset) native;
}
