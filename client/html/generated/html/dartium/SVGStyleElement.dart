
class _SVGStyleElementImpl extends _SVGElementImpl implements SVGStyleElement {
  _SVGStyleElementImpl._wrap(ptr) : super._wrap(ptr);

  bool get disabled() => _wrap(_ptr.disabled);

  void set disabled(bool value) { _ptr.disabled = _unwrap(value); }

  String get media() => _wrap(_ptr.media);

  void set media(String value) { _ptr.media = _unwrap(value); }

  String get type() => _wrap(_ptr.type);

  void set type(String value) { _ptr.type = _unwrap(value); }

  // From SVGLangSpace

  String get xmllang() => _wrap(_ptr.xmllang);

  void set xmllang(String value) { _ptr.xmllang = _unwrap(value); }

  String get xmlspace() => _wrap(_ptr.xmlspace);

  void set xmlspace(String value) { _ptr.xmlspace = _unwrap(value); }
}
