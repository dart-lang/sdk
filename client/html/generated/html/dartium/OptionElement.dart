
class _OptionElementImpl extends _ElementImpl implements OptionElement {
  _OptionElementImpl._wrap(ptr) : super._wrap(ptr);

  bool get defaultSelected() => _wrap(_ptr.defaultSelected);

  void set defaultSelected(bool value) { _ptr.defaultSelected = _unwrap(value); }

  bool get disabled() => _wrap(_ptr.disabled);

  void set disabled(bool value) { _ptr.disabled = _unwrap(value); }

  FormElement get form() => _wrap(_ptr.form);

  int get index() => _wrap(_ptr.index);

  String get label() => _wrap(_ptr.label);

  void set label(String value) { _ptr.label = _unwrap(value); }

  bool get selected() => _wrap(_ptr.selected);

  void set selected(bool value) { _ptr.selected = _unwrap(value); }

  String get value() => _wrap(_ptr.value);

  void set value(String value) { _ptr.value = _unwrap(value); }
}
