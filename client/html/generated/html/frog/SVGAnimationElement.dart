
class _SVGAnimationElementImpl extends _SVGElementImpl implements SVGAnimationElement native "*SVGAnimationElement" {

  final _SVGElementImpl targetElement;

  num getCurrentTime() native;

  num getSimpleDuration() native;

  num getStartTime() native;

  // From SVGTests

  final _SVGStringListImpl requiredExtensions;

  final _SVGStringListImpl requiredFeatures;

  final _SVGStringListImpl systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From ElementTimeControl

  void beginElement() native;

  void beginElementAt(num offset) native;

  void endElement() native;

  void endElementAt(num offset) native;
}
