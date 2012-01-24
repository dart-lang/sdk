
class HTMLTitleElementJS extends HTMLElementJS implements HTMLTitleElement native "*HTMLTitleElement" {

  String get text() native "return this.text;";

  void set text(String value) native "this.text = value;";
}
