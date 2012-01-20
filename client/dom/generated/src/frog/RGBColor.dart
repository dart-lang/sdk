
class RGBColor native "*RGBColor" {

  CSSPrimitiveValue get blue() native "return this.blue;";

  CSSPrimitiveValue get green() native "return this.green;";

  CSSPrimitiveValue get red() native "return this.red;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
