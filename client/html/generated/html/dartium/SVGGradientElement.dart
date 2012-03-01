
class _SVGGradientElementImpl extends _SVGElementImpl implements SVGGradientElement {
  _SVGGradientElementImpl._wrap(ptr) : super._wrap(ptr);

  SVGAnimatedTransformList get gradientTransform() => _wrap(_ptr.gradientTransform);

  SVGAnimatedEnumeration get gradientUnits() => _wrap(_ptr.gradientUnits);

  SVGAnimatedEnumeration get spreadMethod() => _wrap(_ptr.spreadMethod);

  // From SVGURIReference

  SVGAnimatedString get href() => _wrap(_ptr.href);

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() => _wrap(_ptr.externalResourcesRequired);

  // From SVGStylable

  SVGAnimatedString get _className() => _wrap(_ptr.className);

  CSSStyleDeclaration get style() => _wrap(_ptr.style);

  CSSValue getPresentationAttribute(String name) {
    return _wrap(_ptr.getPresentationAttribute(_unwrap(name)));
  }
}
