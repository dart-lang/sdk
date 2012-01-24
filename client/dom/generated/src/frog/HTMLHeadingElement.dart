
class HTMLHeadingElementJs extends HTMLElementJs implements HTMLHeadingElement native "*HTMLHeadingElement" {

  String get align() native "return this.align;";

  void set align(String value) native "this.align = value;";
}
