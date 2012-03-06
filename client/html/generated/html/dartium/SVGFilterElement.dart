
class _SVGFilterElementImpl extends _SVGElementImpl implements SVGFilterElement {
  _SVGFilterElementImpl._wrap(ptr) : super._wrap(ptr);

  SVGAnimatedInteger get filterResX() => _wrap(_ptr.filterResX);

  SVGAnimatedInteger get filterResY() => _wrap(_ptr.filterResY);

  SVGAnimatedEnumeration get filterUnits() => _wrap(_ptr.filterUnits);

  SVGAnimatedLength get height() => _wrap(_ptr.height);

  SVGAnimatedEnumeration get primitiveUnits() => _wrap(_ptr.primitiveUnits);

  SVGAnimatedLength get width() => _wrap(_ptr.width);

  SVGAnimatedLength get x() => _wrap(_ptr.x);

  SVGAnimatedLength get y() => _wrap(_ptr.y);

  void setFilterRes(int filterResX, int filterResY) {
    _ptr.setFilterRes(_unwrap(filterResX), _unwrap(filterResY));
    return;
  }

  // From SVGURIReference

  SVGAnimatedString get href() => _wrap(_ptr.href);

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
}
