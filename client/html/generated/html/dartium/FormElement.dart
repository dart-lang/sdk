
class _FormElementImpl extends _ElementImpl implements FormElement {
  _FormElementImpl._wrap(ptr) : super._wrap(ptr);

  String get acceptCharset() => _wrap(_ptr.acceptCharset);

  void set acceptCharset(String value) { _ptr.acceptCharset = _unwrap(value); }

  String get action() => _wrap(_ptr.action);

  void set action(String value) { _ptr.action = _unwrap(value); }

  String get autocomplete() => _wrap(_ptr.autocomplete);

  void set autocomplete(String value) { _ptr.autocomplete = _unwrap(value); }

  String get encoding() => _wrap(_ptr.encoding);

  void set encoding(String value) { _ptr.encoding = _unwrap(value); }

  String get enctype() => _wrap(_ptr.enctype);

  void set enctype(String value) { _ptr.enctype = _unwrap(value); }

  int get length() => _wrap(_ptr.length);

  String get method() => _wrap(_ptr.method);

  void set method(String value) { _ptr.method = _unwrap(value); }

  String get name() => _wrap(_ptr.name);

  void set name(String value) { _ptr.name = _unwrap(value); }

  bool get noValidate() => _wrap(_ptr.noValidate);

  void set noValidate(bool value) { _ptr.noValidate = _unwrap(value); }

  String get target() => _wrap(_ptr.target);

  void set target(String value) { _ptr.target = _unwrap(value); }

  bool checkValidity() {
    return _wrap(_ptr.checkValidity());
  }

  void reset() {
    _ptr.reset();
    return;
  }

  void submit() {
    _ptr.submit();
    return;
  }
}
