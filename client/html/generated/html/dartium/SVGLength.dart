
class _SVGLengthImpl extends _DOMTypeBase implements SVGLength {
  _SVGLengthImpl._wrap(ptr) : super._wrap(ptr);

  int get unitType() => _wrap(_ptr.unitType);

  num get value() => _wrap(_ptr.value);

  void set value(num value) { _ptr.value = _unwrap(value); }

  String get valueAsString() => _wrap(_ptr.valueAsString);

  void set valueAsString(String value) { _ptr.valueAsString = _unwrap(value); }

  num get valueInSpecifiedUnits() => _wrap(_ptr.valueInSpecifiedUnits);

  void set valueInSpecifiedUnits(num value) { _ptr.valueInSpecifiedUnits = _unwrap(value); }

  void convertToSpecifiedUnits(int unitType) {
    _ptr.convertToSpecifiedUnits(_unwrap(unitType));
    return;
  }

  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) {
    _ptr.newValueSpecifiedUnits(_unwrap(unitType), _unwrap(valueInSpecifiedUnits));
    return;
  }
}
