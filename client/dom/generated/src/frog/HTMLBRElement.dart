
class HTMLBRElementJS extends HTMLElementJS implements HTMLBRElement native "*HTMLBRElement" {

  String get clear() native "return this.clear;";

  void set clear(String value) native "this.clear = value;";
}
