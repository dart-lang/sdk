
class SVGFilterElement extends SVGElement native "*SVGFilterElement" {

  SVGAnimatedInteger get filterResX() native "return this.filterResX;";

  SVGAnimatedInteger get filterResY() native "return this.filterResY;";

  SVGAnimatedEnumeration get filterUnits() native "return this.filterUnits;";

  SVGAnimatedLength get height() native "return this.height;";

  SVGAnimatedEnumeration get primitiveUnits() native "return this.primitiveUnits;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  void setFilterRes(int filterResX, int filterResY) native;

  // From SVGURIReference

  SVGAnimatedString get href() native "return this.href;";

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;
}
