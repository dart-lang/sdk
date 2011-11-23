
class CSSPrimitiveValue extends CSSValue native "*CSSPrimitiveValue" {

  int primitiveType;

  Counter getCounterValue() native;

  num getFloatValue(int unitType) native;

  RGBColor getRGBColorValue() native;

  Rect getRectValue() native;

  String getStringValue() native;

  void setFloatValue(int unitType, num floatValue) native;

  void setStringValue(int stringType, String stringValue) native;
}
