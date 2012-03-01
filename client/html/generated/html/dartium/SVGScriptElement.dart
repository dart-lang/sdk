
class _SVGScriptElementImpl extends _SVGElementImpl implements SVGScriptElement {
  _SVGScriptElementImpl._wrap(ptr) : super._wrap(ptr);

  String get type() => _wrap(_ptr.type);

  void set type(String value) { _ptr.type = _unwrap(value); }

  // From SVGURIReference

  SVGAnimatedString get href() => _wrap(_ptr.href);

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() => _wrap(_ptr.externalResourcesRequired);
}
