
class _ParamElementImpl extends _ElementImpl implements ParamElement {
  _ParamElementImpl._wrap(ptr) : super._wrap(ptr);

  String get name() => _wrap(_ptr.name);

  void set name(String value) { _ptr.name = _unwrap(value); }

  String get type() => _wrap(_ptr.type);

  void set type(String value) { _ptr.type = _unwrap(value); }

  String get value() => _wrap(_ptr.value);

  void set value(String value) { _ptr.value = _unwrap(value); }

  String get valueType() => _wrap(_ptr.valueType);

  void set valueType(String value) { _ptr.valueType = _unwrap(value); }
}
