
class _OutputElementImpl extends _ElementImpl implements OutputElement {
  _OutputElementImpl._wrap(ptr) : super._wrap(ptr);

  String get defaultValue() => _wrap(_ptr.defaultValue);

  void set defaultValue(String value) { _ptr.defaultValue = _unwrap(value); }

  FormElement get form() => _wrap(_ptr.form);

  DOMSettableTokenList get htmlFor() => _wrap(_ptr.htmlFor);

  void set htmlFor(DOMSettableTokenList value) { _ptr.htmlFor = _unwrap(value); }

  NodeList get labels() => _wrap(_ptr.labels);

  String get name() => _wrap(_ptr.name);

  void set name(String value) { _ptr.name = _unwrap(value); }

  String get type() => _wrap(_ptr.type);

  String get validationMessage() => _wrap(_ptr.validationMessage);

  ValidityState get validity() => _wrap(_ptr.validity);

  String get value() => _wrap(_ptr.value);

  void set value(String value) { _ptr.value = _unwrap(value); }

  bool get willValidate() => _wrap(_ptr.willValidate);

  bool checkValidity() {
    return _wrap(_ptr.checkValidity());
  }

  void setCustomValidity(String error) {
    _ptr.setCustomValidity(_unwrap(error));
    return;
  }
}
