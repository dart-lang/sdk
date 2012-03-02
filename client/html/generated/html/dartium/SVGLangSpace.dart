
class _SVGLangSpaceImpl extends _DOMTypeBase implements SVGLangSpace {
  _SVGLangSpaceImpl._wrap(ptr) : super._wrap(ptr);

  String get xmllang() => _wrap(_ptr.xmllang);

  void set xmllang(String value) { _ptr.xmllang = _unwrap(value); }

  String get xmlspace() => _wrap(_ptr.xmlspace);

  void set xmlspace(String value) { _ptr.xmlspace = _unwrap(value); }
}
