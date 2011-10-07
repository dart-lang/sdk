// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class InputElementWrappingImplementation extends ElementWrappingImplementation implements InputElement {
  InputElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get accept() { return _ptr.accept; }

  void set accept(String value) { _ptr.accept = value; }

  String get accessKey() { return _ptr.accessKey; }

  void set accessKey(String value) { _ptr.accessKey = value; }

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }

  String get alt() { return _ptr.alt; }

  void set alt(String value) { _ptr.alt = value; }

  String get autocomplete() { return _ptr.autocomplete; }

  void set autocomplete(String value) { _ptr.autocomplete = value; }

  bool get autofocus() { return _ptr.autofocus; }

  void set autofocus(bool value) { _ptr.autofocus = value; }

  bool get checked() { return _ptr.checked; }

  void set checked(bool value) { _ptr.checked = value; }

  bool get defaultChecked() { return _ptr.defaultChecked; }

  void set defaultChecked(bool value) { _ptr.defaultChecked = value; }

  String get defaultValue() { return _ptr.defaultValue; }

  void set defaultValue(String value) { _ptr.defaultValue = value; }

  bool get disabled() { return _ptr.disabled; }

  void set disabled(bool value) { _ptr.disabled = value; }

  FileList get files() { return LevelDom.wrapFileList(_ptr.files); }

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  String get formAction() { return _ptr.formAction; }

  void set formAction(String value) { _ptr.formAction = value; }

  String get formEnctype() { return _ptr.formEnctype; }

  void set formEnctype(String value) { _ptr.formEnctype = value; }

  String get formMethod() { return _ptr.formMethod; }

  void set formMethod(String value) { _ptr.formMethod = value; }

  bool get formNoValidate() { return _ptr.formNoValidate; }

  void set formNoValidate(bool value) { _ptr.formNoValidate = value; }

  String get formTarget() { return _ptr.formTarget; }

  void set formTarget(String value) { _ptr.formTarget = value; }

  bool get incremental() { return _ptr.incremental; }

  void set incremental(bool value) { _ptr.incremental = value; }

  bool get indeterminate() { return _ptr.indeterminate; }

  void set indeterminate(bool value) { _ptr.indeterminate = value; }

  ElementList get labels() { return LevelDom.wrapElementList(_ptr.labels); }

  Element get list() { return LevelDom.wrapElement(_ptr.list); }

  String get max() { return _ptr.max; }

  void set max(String value) { _ptr.max = value; }

  int get maxLength() { return _ptr.maxLength; }

  void set maxLength(int value) { _ptr.maxLength = value; }

  String get min() { return _ptr.min; }

  void set min(String value) { _ptr.min = value; }

  bool get multiple() { return _ptr.multiple; }

  void set multiple(bool value) { _ptr.multiple = value; }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  EventListener get onwebkitspeechchange() { return LevelDom.wrapEventListener(_ptr.onwebkitspeechchange); }

  void set onwebkitspeechchange(EventListener value) { _ptr.onwebkitspeechchange = LevelDom.unwrap(value); }

  String get pattern() { return _ptr.pattern; }

  void set pattern(String value) { _ptr.pattern = value; }

  String get placeholder() { return _ptr.placeholder; }

  void set placeholder(String value) { _ptr.placeholder = value; }

  bool get readOnly() { return _ptr.readOnly; }

  void set readOnly(bool value) { _ptr.readOnly = value; }

  bool get required() { return _ptr.required; }

  void set required(bool value) { _ptr.required = value; }

  OptionElement get selectedOption() { return LevelDom.wrapOptionElement(_ptr.selectedOption); }

  String get selectionDirection() { return _ptr.selectionDirection; }

  void set selectionDirection(String value) { _ptr.selectionDirection = value; }

  int get selectionEnd() { return _ptr.selectionEnd; }

  void set selectionEnd(int value) { _ptr.selectionEnd = value; }

  int get selectionStart() { return _ptr.selectionStart; }

  void set selectionStart(int value) { _ptr.selectionStart = value; }

  int get size() { return _ptr.size; }

  void set size(int value) { _ptr.size = value; }

  String get src() { return _ptr.src; }

  void set src(String value) { _ptr.src = value; }

  String get step() { return _ptr.step; }

  void set step(String value) { _ptr.step = value; }

  String get type() { return _ptr.type; }

  void set type(String value) { _ptr.type = value; }

  String get useMap() { return _ptr.useMap; }

  void set useMap(String value) { _ptr.useMap = value; }

  String get validationMessage() { return _ptr.validationMessage; }

  ValidityState get validity() { return LevelDom.wrapValidityState(_ptr.validity); }

  String get value() { return _ptr.value; }

  void set value(String value) { _ptr.value = value; }

  Date get valueAsDate() { return _ptr.valueAsDate; }

  void set valueAsDate(Date value) { _ptr.valueAsDate = value; }

  num get valueAsNumber() { return _ptr.valueAsNumber; }

  void set valueAsNumber(num value) { _ptr.valueAsNumber = value; }

  bool get webkitGrammar() { return _ptr.webkitGrammar; }

  void set webkitGrammar(bool value) { _ptr.webkitGrammar = value; }

  bool get webkitSpeech() { return _ptr.webkitSpeech; }

  void set webkitSpeech(bool value) { _ptr.webkitSpeech = value; }

  bool get webkitdirectory() { return _ptr.webkitdirectory; }

  void set webkitdirectory(bool value) { _ptr.webkitdirectory = value; }

  bool get willValidate() { return _ptr.willValidate; }

  bool checkValidity() {
    return _ptr.checkValidity();
  }

  void click() {
    _ptr.click();
    return;
  }

  void select() {
    _ptr.select();
    return;
  }

  void setCustomValidity(String error) {
    _ptr.setCustomValidity(error);
    return;
  }

  void setSelectionRange([int start = null, int end = null, String direction = null]) {
    _ptr.setSelectionRange(start, end, direction);
    return;
  }

  void setValueForUser(String value) {
    _ptr.setValueForUser(value);
    return;
  }

  void stepDown([int n = null]) {
    _ptr.stepDown(n);
    return;
  }

  void stepUp([int n = null]) {
    _ptr.stepUp(n);
    return;
  }

  String get typeName() { return "InputElement"; }
}
