
class _CSSPrimitiveValueImpl extends _CSSValueImpl implements CSSPrimitiveValue {
  _CSSPrimitiveValueImpl._wrap(ptr) : super._wrap(ptr);

  int get primitiveType() => _wrap(_ptr.primitiveType);

  Counter getCounterValue() {
    return _wrap(_ptr.getCounterValue());
  }

  num getFloatValue(int unitType) {
    return _wrap(_ptr.getFloatValue(_unwrap(unitType)));
  }

  RGBColor getRGBColorValue() {
    return _wrap(_ptr.getRGBColorValue());
  }

  Rect getRectValue() {
    return _wrap(_ptr.getRectValue());
  }

  String getStringValue() {
    return _wrap(_ptr.getStringValue());
  }

  void setFloatValue(int unitType, num floatValue) {
    _ptr.setFloatValue(_unwrap(unitType), _unwrap(floatValue));
    return;
  }

  void setStringValue(int stringType, String stringValue) {
    _ptr.setStringValue(_unwrap(stringType), _unwrap(stringValue));
    return;
  }
}
