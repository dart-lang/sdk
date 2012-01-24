
class RGBColorJS implements RGBColor native "*RGBColor" {

  CSSPrimitiveValueJS get blue() native "return this.blue;";

  CSSPrimitiveValueJS get green() native "return this.green;";

  CSSPrimitiveValueJS get red() native "return this.red;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
