
class _SVGTextContentElementImpl extends _SVGElementImpl implements SVGTextContentElement {
  _SVGTextContentElementImpl._wrap(ptr) : super._wrap(ptr);

  SVGAnimatedEnumeration get lengthAdjust() => _wrap(_ptr.lengthAdjust);

  SVGAnimatedLength get textLength() => _wrap(_ptr.textLength);

  int getCharNumAtPosition(SVGPoint point) {
    return _wrap(_ptr.getCharNumAtPosition(_unwrap(point)));
  }

  num getComputedTextLength() {
    return _wrap(_ptr.getComputedTextLength());
  }

  SVGPoint getEndPositionOfChar(int offset) {
    return _wrap(_ptr.getEndPositionOfChar(_unwrap(offset)));
  }

  SVGRect getExtentOfChar(int offset) {
    return _wrap(_ptr.getExtentOfChar(_unwrap(offset)));
  }

  int getNumberOfChars() {
    return _wrap(_ptr.getNumberOfChars());
  }

  num getRotationOfChar(int offset) {
    return _wrap(_ptr.getRotationOfChar(_unwrap(offset)));
  }

  SVGPoint getStartPositionOfChar(int offset) {
    return _wrap(_ptr.getStartPositionOfChar(_unwrap(offset)));
  }

  num getSubStringLength(int offset, int length) {
    return _wrap(_ptr.getSubStringLength(_unwrap(offset), _unwrap(length)));
  }

  void selectSubString(int offset, int length) {
    _ptr.selectSubString(_unwrap(offset), _unwrap(length));
    return;
  }

  // From SVGTests

  SVGStringList get requiredExtensions() => _wrap(_ptr.requiredExtensions);

  SVGStringList get requiredFeatures() => _wrap(_ptr.requiredFeatures);

  SVGStringList get systemLanguage() => _wrap(_ptr.systemLanguage);

  bool hasExtension(String extension) {
    return _wrap(_ptr.hasExtension(_unwrap(extension)));
  }

  // From SVGLangSpace

  String get xmllang() => _wrap(_ptr.xmllang);

  void set xmllang(String value) { _ptr.xmllang = _unwrap(value); }

  String get xmlspace() => _wrap(_ptr.xmlspace);

  void set xmlspace(String value) { _ptr.xmlspace = _unwrap(value); }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() => _wrap(_ptr.externalResourcesRequired);

  // From SVGStylable

  SVGAnimatedString get _className() => _wrap(_ptr.className);

  CSSStyleDeclaration get style() => _wrap(_ptr.style);

  CSSValue getPresentationAttribute(String name) {
    return _wrap(_ptr.getPresentationAttribute(_unwrap(name)));
  }
}
