
class HTMLLabelElementJs extends HTMLElementJs implements HTMLLabelElement native "*HTMLLabelElement" {

  HTMLElementJs get control() native "return this.control;";

  HTMLFormElementJs get form() native "return this.form;";

  String get htmlFor() native "return this.htmlFor;";

  void set htmlFor(String value) native "this.htmlFor = value;";
}
