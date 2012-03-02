
class _LinkElementImpl extends _ElementImpl implements LinkElement {
  _LinkElementImpl._wrap(ptr) : super._wrap(ptr);

  String get charset() => _wrap(_ptr.charset);

  void set charset(String value) { _ptr.charset = _unwrap(value); }

  bool get disabled() => _wrap(_ptr.disabled);

  void set disabled(bool value) { _ptr.disabled = _unwrap(value); }

  String get href() => _wrap(_ptr.href);

  void set href(String value) { _ptr.href = _unwrap(value); }

  String get hreflang() => _wrap(_ptr.hreflang);

  void set hreflang(String value) { _ptr.hreflang = _unwrap(value); }

  String get media() => _wrap(_ptr.media);

  void set media(String value) { _ptr.media = _unwrap(value); }

  String get rel() => _wrap(_ptr.rel);

  void set rel(String value) { _ptr.rel = _unwrap(value); }

  String get rev() => _wrap(_ptr.rev);

  void set rev(String value) { _ptr.rev = _unwrap(value); }

  StyleSheet get sheet() => _wrap(_ptr.sheet);

  DOMSettableTokenList get sizes() => _wrap(_ptr.sizes);

  void set sizes(DOMSettableTokenList value) { _ptr.sizes = _unwrap(value); }

  String get target() => _wrap(_ptr.target);

  void set target(String value) { _ptr.target = _unwrap(value); }

  String get type() => _wrap(_ptr.type);

  void set type(String value) { _ptr.type = _unwrap(value); }
}
