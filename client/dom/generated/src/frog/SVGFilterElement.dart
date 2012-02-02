
class _SVGFilterElementJs extends _SVGElementJs implements SVGFilterElement native "*SVGFilterElement" {

  _SVGAnimatedIntegerJs get filterResX() native "return this.filterResX;";

  _SVGAnimatedIntegerJs get filterResY() native "return this.filterResY;";

  _SVGAnimatedEnumerationJs get filterUnits() native "return this.filterUnits;";

  _SVGAnimatedLengthJs get height() native "return this.height;";

  _SVGAnimatedEnumerationJs get primitiveUnits() native "return this.primitiveUnits;";

  _SVGAnimatedLengthJs get width() native "return this.width;";

  _SVGAnimatedLengthJs get x() native "return this.x;";

  _SVGAnimatedLengthJs get y() native "return this.y;";

  void setFilterRes(int filterResX, int filterResY) native;

  // From SVGURIReference

  _SVGAnimatedStringJs get href() native "return this.href;";

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  _SVGAnimatedBooleanJs get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  _SVGAnimatedStringJs get className() native "return this.className;";

  _CSSStyleDeclarationJs get style() native "return this.style;";

  _CSSValueJs getPresentationAttribute(String name) native;
}
