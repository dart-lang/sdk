
class HTMLLegendElementJS extends HTMLElementJS implements HTMLLegendElement native "*HTMLLegendElement" {

  String get align() native "return this.align;";

  void set align(String value) native "this.align = value;";

  HTMLFormElementJS get form() native "return this.form;";
}
