
class _SelectElementImpl extends _ElementImpl implements SelectElement {
  _SelectElementImpl._wrap(ptr) : super._wrap(ptr);

  bool get autofocus() => _wrap(_ptr.autofocus);

  void set autofocus(bool value) { _ptr.autofocus = _unwrap(value); }

  bool get disabled() => _wrap(_ptr.disabled);

  void set disabled(bool value) { _ptr.disabled = _unwrap(value); }

  FormElement get form() => _wrap(_ptr.form);

  NodeList get labels() => _wrap(_ptr.labels);

  int get length() => _wrap(_ptr.length);

  void set length(int value) { _ptr.length = _unwrap(value); }

  bool get multiple() => _wrap(_ptr.multiple);

  void set multiple(bool value) { _ptr.multiple = _unwrap(value); }

  String get name() => _wrap(_ptr.name);

  void set name(String value) { _ptr.name = _unwrap(value); }

  HTMLOptionsCollection get options() => _wrap(_ptr.options);

  bool get required() => _wrap(_ptr.required);

  void set required(bool value) { _ptr.required = _unwrap(value); }

  int get selectedIndex() => _wrap(_ptr.selectedIndex);

  void set selectedIndex(int value) { _ptr.selectedIndex = _unwrap(value); }

  int get size() => _wrap(_ptr.size);

  void set size(int value) { _ptr.size = _unwrap(value); }

  String get type() => _wrap(_ptr.type);

  String get validationMessage() => _wrap(_ptr.validationMessage);

  ValidityState get validity() => _wrap(_ptr.validity);

  String get value() => _wrap(_ptr.value);

  void set value(String value) { _ptr.value = _unwrap(value); }

  bool get willValidate() => _wrap(_ptr.willValidate);

  void add(Element element, Element before) {
    _ptr.add(_unwrap(element), _unwrap(before));
    return;
  }

  bool checkValidity() {
    return _wrap(_ptr.checkValidity());
  }

  Node item(int index) {
    return _wrap(_ptr.item(_unwrap(index)));
  }

  Node namedItem(String name) {
    return _wrap(_ptr.namedItem(_unwrap(name)));
  }

  void setCustomValidity(String error) {
    _ptr.setCustomValidity(_unwrap(error));
    return;
  }
}
