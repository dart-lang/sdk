
class RGBColorJs extends DOMTypeJs implements RGBColor native "*RGBColor" {

  CSSPrimitiveValueJs get blue() native "return this.blue;";

  CSSPrimitiveValueJs get green() native "return this.green;";

  CSSPrimitiveValueJs get red() native "return this.red;";
}
