
class _OptGroupElementImpl extends _ElementImpl implements OptGroupElement {
  _OptGroupElementImpl._wrap(ptr) : super._wrap(ptr);

  bool get disabled() => _wrap(_ptr.disabled);

  void set disabled(bool value) { _ptr.disabled = _unwrap(value); }

  String get label() => _wrap(_ptr.label);

  void set label(String value) { _ptr.label = _unwrap(value); }
}
