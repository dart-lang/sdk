
class HTMLDivElementJs extends HTMLElementJs implements HTMLDivElement native "*HTMLDivElement" {

  String get align() native "return this.align;";

  void set align(String value) native "this.align = value;";
}
