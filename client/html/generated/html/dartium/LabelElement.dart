
class _LabelElementImpl extends _ElementImpl implements LabelElement {
  _LabelElementImpl._wrap(ptr) : super._wrap(ptr);

  Element get control() => _wrap(_ptr.control);

  FormElement get form() => _wrap(_ptr.form);

  String get htmlFor() => _wrap(_ptr.htmlFor);

  void set htmlFor(String value) { _ptr.htmlFor = _unwrap(value); }
}
