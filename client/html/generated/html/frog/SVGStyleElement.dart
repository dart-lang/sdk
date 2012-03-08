
class _SVGStyleElementImpl extends _SVGElementImpl implements SVGStyleElement native "*SVGStyleElement" {

  bool disabled;

  String media;

  // Shadowing definition.
  String get title() native "return this.title;";

  void set title(String value) native "this.title = value;";

  String type;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;
}
