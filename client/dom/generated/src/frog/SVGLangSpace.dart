
class SVGLangSpaceJS implements SVGLangSpace native "*SVGLangSpace" {

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
