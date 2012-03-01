
class _KeygenElementImpl extends _ElementImpl implements KeygenElement {
  _KeygenElementImpl._wrap(ptr) : super._wrap(ptr);

  bool get autofocus() => _wrap(_ptr.autofocus);

  void set autofocus(bool value) { _ptr.autofocus = _unwrap(value); }

  String get challenge() => _wrap(_ptr.challenge);

  void set challenge(String value) { _ptr.challenge = _unwrap(value); }

  bool get disabled() => _wrap(_ptr.disabled);

  void set disabled(bool value) { _ptr.disabled = _unwrap(value); }

  FormElement get form() => _wrap(_ptr.form);

  String get keytype() => _wrap(_ptr.keytype);

  void set keytype(String value) { _ptr.keytype = _unwrap(value); }

  NodeList get labels() => _wrap(_ptr.labels);

  String get name() => _wrap(_ptr.name);

  void set name(String value) { _ptr.name = _unwrap(value); }

  String get type() => _wrap(_ptr.type);

  String get validationMessage() => _wrap(_ptr.validationMessage);

  ValidityState get validity() => _wrap(_ptr.validity);

  bool get willValidate() => _wrap(_ptr.willValidate);

  bool checkValidity() {
    return _wrap(_ptr.checkValidity());
  }

  void setCustomValidity(String error) {
    _ptr.setCustomValidity(_unwrap(error));
    return;
  }
}
