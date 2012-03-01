
class _TextAreaElementImpl extends _ElementImpl implements TextAreaElement {
  _TextAreaElementImpl._wrap(ptr) : super._wrap(ptr);

  bool get autofocus() => _wrap(_ptr.autofocus);

  void set autofocus(bool value) { _ptr.autofocus = _unwrap(value); }

  int get cols() => _wrap(_ptr.cols);

  void set cols(int value) { _ptr.cols = _unwrap(value); }

  String get defaultValue() => _wrap(_ptr.defaultValue);

  void set defaultValue(String value) { _ptr.defaultValue = _unwrap(value); }

  bool get disabled() => _wrap(_ptr.disabled);

  void set disabled(bool value) { _ptr.disabled = _unwrap(value); }

  FormElement get form() => _wrap(_ptr.form);

  NodeList get labels() => _wrap(_ptr.labels);

  int get maxLength() => _wrap(_ptr.maxLength);

  void set maxLength(int value) { _ptr.maxLength = _unwrap(value); }

  String get name() => _wrap(_ptr.name);

  void set name(String value) { _ptr.name = _unwrap(value); }

  String get placeholder() => _wrap(_ptr.placeholder);

  void set placeholder(String value) { _ptr.placeholder = _unwrap(value); }

  bool get readOnly() => _wrap(_ptr.readOnly);

  void set readOnly(bool value) { _ptr.readOnly = _unwrap(value); }

  bool get required() => _wrap(_ptr.required);

  void set required(bool value) { _ptr.required = _unwrap(value); }

  int get rows() => _wrap(_ptr.rows);

  void set rows(int value) { _ptr.rows = _unwrap(value); }

  String get selectionDirection() => _wrap(_ptr.selectionDirection);

  void set selectionDirection(String value) { _ptr.selectionDirection = _unwrap(value); }

  int get selectionEnd() => _wrap(_ptr.selectionEnd);

  void set selectionEnd(int value) { _ptr.selectionEnd = _unwrap(value); }

  int get selectionStart() => _wrap(_ptr.selectionStart);

  void set selectionStart(int value) { _ptr.selectionStart = _unwrap(value); }

  int get textLength() => _wrap(_ptr.textLength);

  String get type() => _wrap(_ptr.type);

  String get validationMessage() => _wrap(_ptr.validationMessage);

  ValidityState get validity() => _wrap(_ptr.validity);

  String get value() => _wrap(_ptr.value);

  void set value(String value) { _ptr.value = _unwrap(value); }

  bool get willValidate() => _wrap(_ptr.willValidate);

  String get wrap() => _wrap(_ptr.wrap);

  void set wrap(String value) { _ptr.wrap = _unwrap(value); }

  bool checkValidity() {
    return _wrap(_ptr.checkValidity());
  }

  void select() {
    _ptr.select();
    return;
  }

  void setCustomValidity(String error) {
    _ptr.setCustomValidity(_unwrap(error));
    return;
  }

  void setSelectionRange(int start, int end, [String direction = null]) {
    if (direction === null) {
      _ptr.setSelectionRange(_unwrap(start), _unwrap(end));
      return;
    } else {
      _ptr.setSelectionRange(_unwrap(start), _unwrap(end), _unwrap(direction));
      return;
    }
  }
}
