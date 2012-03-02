
class _StyleElementImpl extends _ElementImpl implements StyleElement {
  _StyleElementImpl._wrap(ptr) : super._wrap(ptr);

  bool get disabled() => _wrap(_ptr.disabled);

  void set disabled(bool value) { _ptr.disabled = _unwrap(value); }

  String get media() => _wrap(_ptr.media);

  void set media(String value) { _ptr.media = _unwrap(value); }

  StyleSheet get sheet() => _wrap(_ptr.sheet);

  String get type() => _wrap(_ptr.type);

  void set type(String value) { _ptr.type = _unwrap(value); }
}
