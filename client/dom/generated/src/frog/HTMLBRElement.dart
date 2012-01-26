
class HTMLBRElementJs extends HTMLElementJs implements HTMLBRElement native "*HTMLBRElement" {

  String get clear() native "return this.clear;";

  void set clear(String value) native "this.clear = value;";
}
