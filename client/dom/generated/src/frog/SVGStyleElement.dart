
class SVGStyleElement extends SVGElement native "*SVGStyleElement" {

  String get media() native "return this.media;";

  void set media(String value) native "this.media = value;";

  String get title() native "return this.title;";

  void set title(String value) native "this.title = value;";

  String get type() native "return this.type;";

  void set type(String value) native "this.type = value;";

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";
}
