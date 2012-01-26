
class SVGFilterElementJs extends SVGElementJs implements SVGFilterElement native "*SVGFilterElement" {

  SVGAnimatedIntegerJs get filterResX() native "return this.filterResX;";

  SVGAnimatedIntegerJs get filterResY() native "return this.filterResY;";

  SVGAnimatedEnumerationJs get filterUnits() native "return this.filterUnits;";

  SVGAnimatedLengthJs get height() native "return this.height;";

  SVGAnimatedEnumerationJs get primitiveUnits() native "return this.primitiveUnits;";

  SVGAnimatedLengthJs get width() native "return this.width;";

  SVGAnimatedLengthJs get x() native "return this.x;";

  SVGAnimatedLengthJs get y() native "return this.y;";

  void setFilterRes(int filterResX, int filterResY) native;

  // From SVGURIReference

  SVGAnimatedStringJs get href() native "return this.href;";

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBooleanJs get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedStringJs get className() native "return this.className;";

  CSSStyleDeclarationJs get style() native "return this.style;";

  CSSValueJs getPresentationAttribute(String name) native;
}
