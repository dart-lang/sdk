
class _SVGMarkerElementImpl extends _SVGElementImpl implements SVGMarkerElement {
  _SVGMarkerElementImpl._wrap(ptr) : super._wrap(ptr);

  SVGAnimatedLength get markerHeight() => _wrap(_ptr.markerHeight);

  SVGAnimatedEnumeration get markerUnits() => _wrap(_ptr.markerUnits);

  SVGAnimatedLength get markerWidth() => _wrap(_ptr.markerWidth);

  SVGAnimatedAngle get orientAngle() => _wrap(_ptr.orientAngle);

  SVGAnimatedEnumeration get orientType() => _wrap(_ptr.orientType);

  SVGAnimatedLength get refX() => _wrap(_ptr.refX);

  SVGAnimatedLength get refY() => _wrap(_ptr.refY);

  void setOrientToAngle(SVGAngle angle) {
    _ptr.setOrientToAngle(_unwrap(angle));
    return;
  }

  void setOrientToAuto() {
    _ptr.setOrientToAuto();
    return;
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

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() => _wrap(_ptr.preserveAspectRatio);

  SVGAnimatedRect get viewBox() => _wrap(_ptr.viewBox);
}
