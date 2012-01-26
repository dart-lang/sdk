
class HTMLLegendElementJs extends HTMLElementJs implements HTMLLegendElement native "*HTMLLegendElement" {

  String get align() native "return this.align;";

  void set align(String value) native "this.align = value;";

  HTMLFormElementJs get form() native "return this.form;";
}
