
class _ObjectElementImpl extends _ElementImpl implements ObjectElement {
  _ObjectElementImpl._wrap(ptr) : super._wrap(ptr);

  String get align() => _wrap(_ptr.align);

  void set align(String value) { _ptr.align = _unwrap(value); }

  String get archive() => _wrap(_ptr.archive);

  void set archive(String value) { _ptr.archive = _unwrap(value); }

  String get border() => _wrap(_ptr.border);

  void set border(String value) { _ptr.border = _unwrap(value); }

  String get code() => _wrap(_ptr.code);

  void set code(String value) { _ptr.code = _unwrap(value); }

  String get codeBase() => _wrap(_ptr.codeBase);

  void set codeBase(String value) { _ptr.codeBase = _unwrap(value); }

  String get codeType() => _wrap(_ptr.codeType);

  void set codeType(String value) { _ptr.codeType = _unwrap(value); }

  Document get contentDocument() => _FixHtmlDocumentReference(_wrap(_ptr.contentDocument));

  String get data() => _wrap(_ptr.data);

  void set data(String value) { _ptr.data = _unwrap(value); }

  bool get declare() => _wrap(_ptr.declare);

  void set declare(bool value) { _ptr.declare = _unwrap(value); }

  FormElement get form() => _wrap(_ptr.form);

  String get height() => _wrap(_ptr.height);

  void set height(String value) { _ptr.height = _unwrap(value); }

  int get hspace() => _wrap(_ptr.hspace);

  void set hspace(int value) { _ptr.hspace = _unwrap(value); }

  String get name() => _wrap(_ptr.name);

  void set name(String value) { _ptr.name = _unwrap(value); }

  String get standby() => _wrap(_ptr.standby);

  void set standby(String value) { _ptr.standby = _unwrap(value); }

  String get type() => _wrap(_ptr.type);

  void set type(String value) { _ptr.type = _unwrap(value); }

  String get useMap() => _wrap(_ptr.useMap);

  void set useMap(String value) { _ptr.useMap = _unwrap(value); }

  String get validationMessage() => _wrap(_ptr.validationMessage);

  ValidityState get validity() => _wrap(_ptr.validity);

  int get vspace() => _wrap(_ptr.vspace);

  void set vspace(int value) { _ptr.vspace = _unwrap(value); }

  String get width() => _wrap(_ptr.width);

  void set width(String value) { _ptr.width = _unwrap(value); }

  bool get willValidate() => _wrap(_ptr.willValidate);

  bool checkValidity() {
    return _wrap(_ptr.checkValidity());
  }

  void setCustomValidity(String error) {
    _ptr.setCustomValidity(_unwrap(error));
    return;
  }
}
