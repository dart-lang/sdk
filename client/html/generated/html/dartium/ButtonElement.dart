
class _ButtonElementImpl extends _ElementImpl implements ButtonElement {
  _ButtonElementImpl._wrap(ptr) : super._wrap(ptr);

  bool get autofocus() => _wrap(_ptr.autofocus);

  void set autofocus(bool value) { _ptr.autofocus = _unwrap(value); }

  bool get disabled() => _wrap(_ptr.disabled);

  void set disabled(bool value) { _ptr.disabled = _unwrap(value); }

  FormElement get form() => _wrap(_ptr.form);

  String get formAction() => _wrap(_ptr.formAction);

  void set formAction(String value) { _ptr.formAction = _unwrap(value); }

  String get formEnctype() => _wrap(_ptr.formEnctype);

  void set formEnctype(String value) { _ptr.formEnctype = _unwrap(value); }

  String get formMethod() => _wrap(_ptr.formMethod);

  void set formMethod(String value) { _ptr.formMethod = _unwrap(value); }

  bool get formNoValidate() => _wrap(_ptr.formNoValidate);

  void set formNoValidate(bool value) { _ptr.formNoValidate = _unwrap(value); }

  String get formTarget() => _wrap(_ptr.formTarget);

  void set formTarget(String value) { _ptr.formTarget = _unwrap(value); }

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
