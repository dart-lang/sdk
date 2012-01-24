
class HTMLFontElementJS extends HTMLElementJS implements HTMLFontElement native "*HTMLFontElement" {

  String get color() native "return this.color;";

  void set color(String value) native "this.color = value;";

  String get face() native "return this.face;";

  void set face(String value) native "this.face = value;";

  String get size() native "return this.size;";

  void set size(String value) native "this.size = value;";
}
