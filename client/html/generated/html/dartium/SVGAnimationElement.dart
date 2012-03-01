
class _SVGAnimationElementImpl extends _SVGElementImpl implements SVGAnimationElement {
  _SVGAnimationElementImpl._wrap(ptr) : super._wrap(ptr);

  SVGElement get targetElement() => _wrap(_ptr.targetElement);

  num getCurrentTime() {
    return _wrap(_ptr.getCurrentTime());
  }

  num getSimpleDuration() {
    return _wrap(_ptr.getSimpleDuration());
  }

  num getStartTime() {
    return _wrap(_ptr.getStartTime());
  }

  // From SVGTests

  SVGStringList get requiredExtensions() => _wrap(_ptr.requiredExtensions);

  SVGStringList get requiredFeatures() => _wrap(_ptr.requiredFeatures);

  SVGStringList get systemLanguage() => _wrap(_ptr.systemLanguage);

  bool hasExtension(String extension) {
    return _wrap(_ptr.hasExtension(_unwrap(extension)));
  }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() => _wrap(_ptr.externalResourcesRequired);

  // From ElementTimeControl

  void beginElement() {
    _ptr.beginElement();
    return;
  }

  void beginElementAt(num offset) {
    _ptr.beginElementAt(_unwrap(offset));
    return;
  }

  void endElement() {
    _ptr.endElement();
    return;
  }

  void endElementAt(num offset) {
    _ptr.endElementAt(_unwrap(offset));
    return;
  }
}
