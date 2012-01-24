
class SVGFilterElementJS extends SVGElementJS implements SVGFilterElement native "*SVGFilterElement" {

  SVGAnimatedIntegerJS get filterResX() native "return this.filterResX;";

  SVGAnimatedIntegerJS get filterResY() native "return this.filterResY;";

  SVGAnimatedEnumerationJS get filterUnits() native "return this.filterUnits;";

  SVGAnimatedLengthJS get height() native "return this.height;";

  SVGAnimatedEnumerationJS get primitiveUnits() native "return this.primitiveUnits;";

  SVGAnimatedLengthJS get width() native "return this.width;";

  SVGAnimatedLengthJS get x() native "return this.x;";

  SVGAnimatedLengthJS get y() native "return this.y;";

  void setFilterRes(int filterResX, int filterResY) native;

  // From SVGURIReference

  SVGAnimatedStringJS get href() native "return this.href;";

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBooleanJS get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedStringJS get className() native "return this.className;";

  CSSStyleDeclarationJS get style() native "return this.style;";

  CSSValueJS getPresentationAttribute(String name) native;
}
