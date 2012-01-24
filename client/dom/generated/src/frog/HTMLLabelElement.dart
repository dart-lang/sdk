
class HTMLLabelElementJS extends HTMLElementJS implements HTMLLabelElement native "*HTMLLabelElement" {

  HTMLElementJS get control() native "return this.control;";

  HTMLFormElementJS get form() native "return this.form;";

  String get htmlFor() native "return this.htmlFor;";

  void set htmlFor(String value) native "this.htmlFor = value;";
}
