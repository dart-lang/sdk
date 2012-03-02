
class _LegendElementImpl extends _ElementImpl implements LegendElement {
  _LegendElementImpl._wrap(ptr) : super._wrap(ptr);

  String get align() => _wrap(_ptr.align);

  void set align(String value) { _ptr.align = _unwrap(value); }

  FormElement get form() => _wrap(_ptr.form);
}
