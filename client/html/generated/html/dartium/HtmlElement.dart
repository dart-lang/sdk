
class _HtmlElementImpl extends _ElementImpl implements HtmlElement {
  _HtmlElementImpl._wrap(ptr) : super._wrap(ptr);

  String get manifest() => _wrap(_ptr.manifest);

  void set manifest(String value) { _ptr.manifest = _unwrap(value); }

  String get version() => _wrap(_ptr.version);

  void set version(String value) { _ptr.version = _unwrap(value); }
}
