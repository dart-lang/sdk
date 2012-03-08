
class _SVGSymbolElementImpl extends _SVGElementImpl implements SVGSymbolElement {
  _SVGSymbolElementImpl._wrap(ptr) : super._wrap(ptr);

  // From SVGLangSpace

  String get xmllang() => _wrap(_ptr.xmllang);

  void set xmllang(String value) { _ptr.xmllang = _unwrap(value); }

  String get xmlspace() => _wrap(_ptr.xmlspace);

  void set xmlspace(String value) { _ptr.xmlspace = _unwrap(value); }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() => _wrap(_ptr.externalResourcesRequired);

  // From SVGStylable

  SVGAnimatedString get _svgClassName() => _wrap(_ptr.className);

  CSSStyleDeclaration get style() => _wrap(_ptr.style);

  CSSValue getPresentationAttribute(String name) {
    return _wrap(_ptr.getPresentationAttribute(_unwrap(name)));
  }

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() => _wrap(_ptr.preserveAspectRatio);

  SVGAnimatedRect get viewBox() => _wrap(_ptr.viewBox);
}
