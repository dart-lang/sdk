
class HTMLParagraphElementJs extends HTMLElementJs implements HTMLParagraphElement native "*HTMLParagraphElement" {

  String get align() native "return this.align;";

  void set align(String value) native "this.align = value;";
}
