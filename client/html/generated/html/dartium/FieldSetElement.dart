
class _FieldSetElementImpl extends _ElementImpl implements FieldSetElement {
  _FieldSetElementImpl._wrap(ptr) : super._wrap(ptr);

  FormElement get form() => _wrap(_ptr.form);

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
