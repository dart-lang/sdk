
class _InputElementImpl extends _ElementImpl implements InputElement {
  _InputElementImpl._wrap(ptr) : super._wrap(ptr);

  String get accept() => _wrap(_ptr.accept);

  void set accept(String value) { _ptr.accept = _unwrap(value); }

  String get align() => _wrap(_ptr.align);

  void set align(String value) { _ptr.align = _unwrap(value); }

  String get alt() => _wrap(_ptr.alt);

  void set alt(String value) { _ptr.alt = _unwrap(value); }

  String get autocomplete() => _wrap(_ptr.autocomplete);

  void set autocomplete(String value) { _ptr.autocomplete = _unwrap(value); }

  bool get autofocus() => _wrap(_ptr.autofocus);

  void set autofocus(bool value) { _ptr.autofocus = _unwrap(value); }

  bool get checked() => _wrap(_ptr.checked);

  void set checked(bool value) { _ptr.checked = _unwrap(value); }

  bool get defaultChecked() => _wrap(_ptr.defaultChecked);

  void set defaultChecked(bool value) { _ptr.defaultChecked = _unwrap(value); }

  String get defaultValue() => _wrap(_ptr.defaultValue);

  void set defaultValue(String value) { _ptr.defaultValue = _unwrap(value); }

  bool get disabled() => _wrap(_ptr.disabled);

  void set disabled(bool value) { _ptr.disabled = _unwrap(value); }

  FileList get files() => _wrap(_ptr.files);

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

  bool get incremental() => _wrap(_ptr.incremental);

  void set incremental(bool value) { _ptr.incremental = _unwrap(value); }

  bool get indeterminate() => _wrap(_ptr.indeterminate);

  void set indeterminate(bool value) { _ptr.indeterminate = _unwrap(value); }

  NodeList get labels() => _wrap(_ptr.labels);

  String get max() => _wrap(_ptr.max);

  void set max(String value) { _ptr.max = _unwrap(value); }

  int get maxLength() => _wrap(_ptr.maxLength);

  void set maxLength(int value) { _ptr.maxLength = _unwrap(value); }

  String get min() => _wrap(_ptr.min);

  void set min(String value) { _ptr.min = _unwrap(value); }

  bool get multiple() => _wrap(_ptr.multiple);

  void set multiple(bool value) { _ptr.multiple = _unwrap(value); }

  String get name() => _wrap(_ptr.name);

  void set name(String value) { _ptr.name = _unwrap(value); }

  String get pattern() => _wrap(_ptr.pattern);

  void set pattern(String value) { _ptr.pattern = _unwrap(value); }

  String get placeholder() => _wrap(_ptr.placeholder);

  void set placeholder(String value) { _ptr.placeholder = _unwrap(value); }

  bool get readOnly() => _wrap(_ptr.readOnly);

  void set readOnly(bool value) { _ptr.readOnly = _unwrap(value); }

  bool get required() => _wrap(_ptr.required);

  void set required(bool value) { _ptr.required = _unwrap(value); }

  String get selectionDirection() => _wrap(_ptr.selectionDirection);

  void set selectionDirection(String value) { _ptr.selectionDirection = _unwrap(value); }

  int get selectionEnd() => _wrap(_ptr.selectionEnd);

  void set selectionEnd(int value) { _ptr.selectionEnd = _unwrap(value); }

  int get selectionStart() => _wrap(_ptr.selectionStart);

  void set selectionStart(int value) { _ptr.selectionStart = _unwrap(value); }

  int get size() => _wrap(_ptr.size);

  void set size(int value) { _ptr.size = _unwrap(value); }

  String get src() => _wrap(_ptr.src);

  void set src(String value) { _ptr.src = _unwrap(value); }

  String get step() => _wrap(_ptr.step);

  void set step(String value) { _ptr.step = _unwrap(value); }

  String get type() => _wrap(_ptr.type);

  void set type(String value) { _ptr.type = _unwrap(value); }

  String get useMap() => _wrap(_ptr.useMap);

  void set useMap(String value) { _ptr.useMap = _unwrap(value); }

  String get validationMessage() => _wrap(_ptr.validationMessage);

  ValidityState get validity() => _wrap(_ptr.validity);

  String get value() => _wrap(_ptr.value);

  void set value(String value) { _ptr.value = _unwrap(value); }

  Date get valueAsDate() => _wrap(_ptr.valueAsDate);

  void set valueAsDate(Date value) { _ptr.valueAsDate = _unwrap(value); }

  num get valueAsNumber() => _wrap(_ptr.valueAsNumber);

  void set valueAsNumber(num value) { _ptr.valueAsNumber = _unwrap(value); }

  bool get webkitGrammar() => _wrap(_ptr.webkitGrammar);

  void set webkitGrammar(bool value) { _ptr.webkitGrammar = _unwrap(value); }

  bool get webkitSpeech() => _wrap(_ptr.webkitSpeech);

  void set webkitSpeech(bool value) { _ptr.webkitSpeech = _unwrap(value); }

  bool get webkitdirectory() => _wrap(_ptr.webkitdirectory);

  void set webkitdirectory(bool value) { _ptr.webkitdirectory = _unwrap(value); }

  bool get willValidate() => _wrap(_ptr.willValidate);

  _InputElementEventsImpl get on() {
    if (_on == null) _on = new _InputElementEventsImpl(this);
    return _on;
  }

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

  void stepDown([int n = null]) {
    if (n === null) {
      _ptr.stepDown();
      return;
    } else {
      _ptr.stepDown(_unwrap(n));
      return;
    }
  }

  void stepUp([int n = null]) {
    if (n === null) {
      _ptr.stepUp();
      return;
    } else {
      _ptr.stepUp(_unwrap(n));
      return;
    }
  }
}

class _InputElementEventsImpl extends _ElementEventsImpl implements InputElementEvents {
  _InputElementEventsImpl(_ptr) : super(_ptr);

  EventListenerList get speechChange() => _get('webkitSpeechChange');
}
