
class _MetaElementImpl extends _ElementImpl implements MetaElement {
  _MetaElementImpl._wrap(ptr) : super._wrap(ptr);

  String get content() => _wrap(_ptr.content);

  void set content(String value) { _ptr.content = _unwrap(value); }

  String get httpEquiv() => _wrap(_ptr.httpEquiv);

  void set httpEquiv(String value) { _ptr.httpEquiv = _unwrap(value); }

  String get name() => _wrap(_ptr.name);

  void set name(String value) { _ptr.name = _unwrap(value); }

  String get scheme() => _wrap(_ptr.scheme);

  void set scheme(String value) { _ptr.scheme = _unwrap(value); }
}
